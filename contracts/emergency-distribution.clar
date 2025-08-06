;; Emergency Supply Distribution Contract
;; Coordinates distribution of supplies during disasters and emergencies

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-INPUT (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-SUPPLY (err u300))
(define-constant ERR-EMERGENCY-NOT-ACTIVE (err u301))
(define-constant ERR-INVALID-PRIORITY (err u302))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures
(define-map emergencies
  { emergency-id: uint }
  {
    type: (string-ascii 30),
    location: (string-ascii 50),
    severity: uint,
    declared-at: uint,
    declared-by: principal,
    status: (string-ascii 20),
    estimated-affected: uint,
    resolved-at: (optional uint)
  }
)

(define-map emergency-supplies
  { supply-id: uint }
  {
    name: (string-ascii 50),
    category: (string-ascii 30),
    unit: (string-ascii 20),
    quantity: uint,
    reserved: uint,
    location: (string-ascii 50),
    expiry-date: (optional uint)
  }
)

(define-map distribution-centers
  { center-id: uint }
  {
    name: (string-ascii 50),
    location: (string-ascii 50),
    capacity: uint,
    current-load: uint,
    manager: principal,
    active: bool,
    contact: (string-ascii 50)
  }
)

(define-map distribution-requests
  { request-id: uint }
  {
    emergency-id: uint,
    center-id: uint,
    supply-id: uint,
    quantity: uint,
    priority: uint,
    requested-by: principal,
    status: (string-ascii 20),
    requested-at: uint,
    fulfilled-at: (optional uint)
  }
)

(define-map allocations
  { allocation-id: uint }
  {
    request-id: uint,
    supply-id: uint,
    quantity: uint,
    allocated-by: principal,
    allocated-at: uint,
    delivery-status: (string-ascii 20),
    estimated-delivery: uint
  }
)

;; Counters
(define-data-var next-emergency-id uint u1)
(define-data-var next-supply-id uint u1)
(define-data-var next-center-id uint u1)
(define-data-var next-request-id uint u1)
(define-data-var next-allocation-id uint u1)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender CONTRACT-OWNER)
)

;; Declare emergency
(define-public (declare-emergency (emergency-type (string-ascii 30)) (location (string-ascii 50)) (severity uint) (estimated-affected uint))
  (let ((emergency-id (var-get next-emergency-id)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len emergency-type) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= severity u1) (<= severity u5)) ERR-INVALID-INPUT)
    (asserts! (> estimated-affected u0) ERR-INVALID-INPUT)

    (map-set emergencies
      { emergency-id: emergency-id }
      {
        type: emergency-type,
        location: location,
        severity: severity,
        declared-at: block-height,
        declared-by: tx-sender,
        status: "active",
        estimated-affected: estimated-affected,
        resolved-at: none
      }
    )

    (var-set next-emergency-id (+ emergency-id u1))
    (ok emergency-id)
  )
)

;; Add emergency supply
(define-public (add-emergency-supply (name (string-ascii 50)) (category (string-ascii 30)) (unit (string-ascii 20)) (quantity uint) (location (string-ascii 50)))
  (let ((supply-id (var-get next-supply-id)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> quantity u0) ERR-INVALID-INPUT)

    (map-set emergency-supplies
      { supply-id: supply-id }
      {
        name: name,
        category: category,
        unit: unit,
        quantity: quantity,
        reserved: u0,
        location: location,
        expiry-date: none
      }
    )

    (var-set next-supply-id (+ supply-id u1))
    (ok supply-id)
  )
)

;; Register distribution center
(define-public (register-distribution-center (name (string-ascii 50)) (location (string-ascii 50)) (capacity uint) (manager principal) (contact (string-ascii 50)))
  (let ((center-id (var-get next-center-id)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> capacity u0) ERR-INVALID-INPUT)

    (map-set distribution-centers
      { center-id: center-id }
      {
        name: name,
        location: location,
        capacity: capacity,
        current-load: u0,
        manager: manager,
        active: true,
        contact: contact
      }
    )

    (var-set next-center-id (+ center-id u1))
    (ok center-id)
  )
)

;; Request supplies
(define-public (request-supplies (emergency-id uint) (center-id uint) (supply-id uint) (quantity uint) (priority uint))
  (let ((request-id (var-get next-request-id))
        (emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) ERR-NOT-FOUND))
        (center (unwrap! (map-get? distribution-centers { center-id: center-id }) ERR-NOT-FOUND))
        (supply (unwrap! (map-get? emergency-supplies { supply-id: supply-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq (get status emergency) "active") ERR-EMERGENCY-NOT-ACTIVE)
    (asserts! (get active center) ERR-INVALID-INPUT)
    (asserts! (and (>= priority u1) (<= priority u5)) ERR-INVALID-PRIORITY)
    (asserts! (> quantity u0) ERR-INVALID-INPUT)

    (map-set distribution-requests
      { request-id: request-id }
      {
        emergency-id: emergency-id,
        center-id: center-id,
        supply-id: supply-id,
        quantity: quantity,
        priority: priority,
        requested-by: tx-sender,
        status: "pending",
        requested-at: block-height,
        fulfilled-at: none
      }
    )

    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Allocate supplies
(define-public (allocate-supplies (request-id uint) (estimated-delivery uint))
  (let ((allocation-id (var-get next-allocation-id))
        (request (unwrap! (map-get? distribution-requests { request-id: request-id }) ERR-NOT-FOUND))
        (supply (unwrap! (map-get? emergency-supplies { supply-id: (get supply-id request) }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "pending") ERR-INVALID-INPUT)
    (asserts! (>= (- (get quantity supply) (get reserved supply)) (get quantity request)) ERR-INSUFFICIENT-SUPPLY)
    (asserts! (> estimated-delivery block-height) ERR-INVALID-INPUT)

    ;; Update supply reservation
    (map-set emergency-supplies
      { supply-id: (get supply-id request) }
      (merge supply { reserved: (+ (get reserved supply) (get quantity request)) })
    )

    ;; Update request status
    (map-set distribution-requests
      { request-id: request-id }
      (merge request { status: "allocated" })
    )

    ;; Create allocation record
    (map-set allocations
      { allocation-id: allocation-id }
      {
        request-id: request-id,
        supply-id: (get supply-id request),
        quantity: (get quantity request),
        allocated-by: tx-sender,
        allocated-at: block-height,
        delivery-status: "preparing",
        estimated-delivery: estimated-delivery
      }
    )

    (var-set next-allocation-id (+ allocation-id u1))
    (ok allocation-id)
  )
)

;; Confirm delivery
(define-public (confirm-delivery (allocation-id uint))
  (let ((allocation (unwrap! (map-get? allocations { allocation-id: allocation-id }) ERR-NOT-FOUND))
        (request (unwrap! (map-get? distribution-requests { request-id: (get request-id allocation) }) ERR-NOT-FOUND))
        (supply (unwrap! (map-get? emergency-supplies { supply-id: (get supply-id allocation) }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get delivery-status allocation) "preparing") ERR-INVALID-INPUT)

    ;; Update allocation status
    (map-set allocations
      { allocation-id: allocation-id }
      (merge allocation { delivery-status: "delivered" })
    )

    ;; Update request status
    (map-set distribution-requests
      { request-id: (get request-id allocation) }
      (merge request { status: "fulfilled", fulfilled-at: (some block-height) })
    )

    ;; Update supply quantities
    (map-set emergency-supplies
      { supply-id: (get supply-id allocation) }
      (merge supply {
        quantity: (- (get quantity supply) (get quantity allocation)),
        reserved: (- (get reserved supply) (get quantity allocation))
      })
    )

    (ok true)
  )
)

;; Resolve emergency
(define-public (resolve-emergency (emergency-id uint))
  (let ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status emergency) "active") ERR-INVALID-INPUT)

    (map-set emergencies
      { emergency-id: emergency-id }
      (merge emergency { status: "resolved", resolved-at: (some block-height) })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-emergency (emergency-id uint))
  (map-get? emergencies { emergency-id: emergency-id })
)

(define-read-only (get-emergency-supply (supply-id uint))
  (map-get? emergency-supplies { supply-id: supply-id })
)

(define-read-only (get-distribution-center (center-id uint))
  (map-get? distribution-centers { center-id: center-id })
)

(define-read-only (get-distribution-request (request-id uint))
  (map-get? distribution-requests { request-id: request-id })
)

(define-read-only (get-allocation (allocation-id uint))
  (map-get? allocations { allocation-id: allocation-id })
)

(define-read-only (get-emergency-stats)
  {
    total-emergencies: (- (var-get next-emergency-id) u1),
    total-supplies: (- (var-get next-supply-id) u1),
    total-centers: (- (var-get next-center-id) u1),
    total-requests: (- (var-get next-request-id) u1),
    total-allocations: (- (var-get next-allocation-id) u1)
  }
)
