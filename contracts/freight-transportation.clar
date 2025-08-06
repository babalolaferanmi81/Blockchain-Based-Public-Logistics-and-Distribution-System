;; Freight and Cargo Transportation Contract
;; Coordinates movement of goods through ports, airports, and highways

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-INPUT (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-CAPACITY (err u300))
(define-constant ERR-INVALID-STATUS (err u301))
(define-constant ERR-SCHEDULE-CONFLICT (err u302))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures
(define-map cargo-manifests
  { manifest-id: uint }
  {
    shipper: principal,
    cargo-type: (string-ascii 30),
    description: (string-ascii 200),
    weight: uint,
    volume: uint,
    value: uint,
    origin: (string-ascii 50),
    destination: (string-ascii 50),
    status: (string-ascii 20),
    created-at: uint,
    priority: uint
  }
)

(define-map transportation-hubs
  { hub-id: uint }
  {
    name: (string-ascii 50),
    hub-type: (string-ascii 20),
    location: (string-ascii 50),
    capacity: uint,
    current-load: uint,
    operational-hours: (string-ascii 20),
    manager: principal,
    active: bool
  }
)

(define-map freight-vehicles
  { vehicle-id: uint }
  {
    type: (string-ascii 20),
    capacity-weight: uint,
    capacity-volume: uint,
    current-weight: uint,
    current-volume: uint,
    status: (string-ascii 20),
    location: (string-ascii 50),
    driver: (optional principal),
    last-maintenance: uint
  }
)

(define-map transportation-schedules
  { schedule-id: uint }
  {
    manifest-id: uint,
    vehicle-id: uint,
    origin-hub: uint,
    destination-hub: uint,
    departure-time: uint,
    estimated-arrival: uint,
    actual-arrival: (optional uint),
    status: (string-ascii 20),
    route-type: (string-ascii 20)
  }
)

(define-map container-tracking
  { container-id: uint }
  {
    container-number: (string-ascii 20),
    type: (string-ascii 20),
    size: (string-ascii 10),
    weight: uint,
    current-location: (string-ascii 50),
    status: (string-ascii 20),
    last-updated: uint,
    assigned-manifest: (optional uint)
  }
)

;; Counters
(define-data-var next-manifest-id uint u1)
(define-data-var next-hub-id uint u1)
(define-data-var next-vehicle-id uint u1)
(define-data-var next-schedule-id uint u1)
(define-data-var next-container-id uint u1)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender CONTRACT-OWNER)
)

;; Create cargo manifest
(define-public (create-cargo-manifest (cargo-type (string-ascii 30)) (description (string-ascii 200)) (weight uint) (volume uint) (value uint) (origin (string-ascii 50)) (destination (string-ascii 50)) (priority uint))
  (let ((manifest-id (var-get next-manifest-id)))
    (asserts! (> (len cargo-type) u0) ERR-INVALID-INPUT)
    (asserts! (> weight u0) ERR-INVALID-INPUT)
    (asserts! (> volume u0) ERR-INVALID-INPUT)
    (asserts! (> value u0) ERR-INVALID-INPUT)
    (asserts! (and (>= priority u1) (<= priority u5)) ERR-INVALID-INPUT)

    (map-set cargo-manifests
      { manifest-id: manifest-id }
      {
        shipper: tx-sender,
        cargo-type: cargo-type,
        description: description,
        weight: weight,
        volume: volume,
        value: value,
        origin: origin,
        destination: destination,
        status: "registered",
        created-at: block-height,
        priority: priority
      }
    )

    (var-set next-manifest-id (+ manifest-id u1))
    (ok manifest-id)
  )
)

;; Register transportation hub
(define-public (register-transportation-hub (name (string-ascii 50)) (hub-type (string-ascii 20)) (location (string-ascii 50)) (capacity uint) (operational-hours (string-ascii 20)) (manager principal))
  (let ((hub-id (var-get next-hub-id)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> capacity u0) ERR-INVALID-INPUT)

    (map-set transportation-hubs
      { hub-id: hub-id }
      {
        name: name,
        hub-type: hub-type,
        location: location,
        capacity: capacity,
        current-load: u0,
        operational-hours: operational-hours,
        manager: manager,
        active: true
      }
    )

    (var-set next-hub-id (+ hub-id u1))
    (ok hub-id)
  )
)

;; Add freight vehicle
(define-public (add-freight-vehicle (vehicle-type (string-ascii 20)) (capacity-weight uint) (capacity-volume uint) (location (string-ascii 50)))
  (let ((vehicle-id (var-get next-vehicle-id)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len vehicle-type) u0) ERR-INVALID-INPUT)
    (asserts! (> capacity-weight u0) ERR-INVALID-INPUT)
    (asserts! (> capacity-volume u0) ERR-INVALID-INPUT)

    (map-set freight-vehicles
      { vehicle-id: vehicle-id }
      {
        type: vehicle-type,
        capacity-weight: capacity-weight,
        capacity-volume: capacity-volume,
        current-weight: u0,
        current-volume: u0,
        status: "available",
        location: location,
        driver: none,
        last-maintenance: block-height
      }
    )

    (var-set next-vehicle-id (+ vehicle-id u1))
    (ok vehicle-id)
  )
)

;; Schedule transportation
(define-public (schedule-transportation (manifest-id uint) (vehicle-id uint) (origin-hub uint) (destination-hub uint) (departure-time uint) (route-type (string-ascii 20)))
  (let ((schedule-id (var-get next-schedule-id))
        (manifest (unwrap! (map-get? cargo-manifests { manifest-id: manifest-id }) ERR-NOT-FOUND))
        (vehicle (unwrap! (map-get? freight-vehicles { vehicle-id: vehicle-id }) ERR-NOT-FOUND))
        (origin (unwrap! (map-get? transportation-hubs { hub-id: origin-hub }) ERR-NOT-FOUND))
        (destination (unwrap! (map-get? transportation-hubs { hub-id: destination-hub }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status manifest) "registered") ERR-INVALID-STATUS)
    (asserts! (is-eq (get status vehicle) "available") ERR-INVALID-STATUS)
    (asserts! (get active origin) ERR-INVALID-INPUT)
    (asserts! (get active destination) ERR-INVALID-INPUT)
    (asserts! (<= (+ (get current-weight vehicle) (get weight manifest)) (get capacity-weight vehicle)) ERR-INSUFFICIENT-CAPACITY)
    (asserts! (<= (+ (get current-volume vehicle) (get volume manifest)) (get capacity-volume vehicle)) ERR-INSUFFICIENT-CAPACITY)
    (asserts! (> departure-time block-height) ERR-INVALID-INPUT)

    ;; Update manifest status
    (map-set cargo-manifests
      { manifest-id: manifest-id }
      (merge manifest { status: "scheduled" })
    )

    ;; Update vehicle load and status
    (map-set freight-vehicles
      { vehicle-id: vehicle-id }
      (merge vehicle {
        current-weight: (+ (get current-weight vehicle) (get weight manifest)),
        current-volume: (+ (get current-volume vehicle) (get volume manifest)),
        status: "scheduled"
      })
    )

    ;; Create schedule
    (map-set transportation-schedules
      { schedule-id: schedule-id }
      {
        manifest-id: manifest-id,
        vehicle-id: vehicle-id,
        origin-hub: origin-hub,
        destination-hub: destination-hub,
        departure-time: departure-time,
        estimated-arrival: (+ departure-time u50),
        actual-arrival: none,
        status: "scheduled",
        route-type: route-type
      }
    )

    (var-set next-schedule-id (+ schedule-id u1))
    (ok schedule-id)
  )
)

;; Register container
(define-public (register-container (container-number (string-ascii 20)) (container-type (string-ascii 20)) (size (string-ascii 10)) (weight uint) (location (string-ascii 50)))
  (let ((container-id (var-get next-container-id)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len container-number) u0) ERR-INVALID-INPUT)
    (asserts! (> weight u0) ERR-INVALID-INPUT)

    (map-set container-tracking
      { container-id: container-id }
      {
        container-number: container-number,
        type: container-type,
        size: size,
        weight: weight,
        current-location: location,
        status: "available",
        last-updated: block-height,
        assigned-manifest: none
      }
    )

    (var-set next-container-id (+ container-id u1))
    (ok container-id)
  )
)

;; Update transportation status
(define-public (update-transportation-status (schedule-id uint) (new-status (string-ascii 20)))
  (let ((schedule (unwrap! (map-get? transportation-schedules { schedule-id: schedule-id }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)

    (map-set transportation-schedules
      { schedule-id: schedule-id }
      (merge schedule { status: new-status })
    )

    ;; If completed, update arrival time
    (if (is-eq new-status "completed")
      (map-set transportation-schedules
        { schedule-id: schedule-id }
        (merge schedule { status: new-status, actual-arrival: (some block-height) })
      )
      true
    )

    (ok true)
  )
)

;; Assign container to manifest
(define-public (assign-container-to-manifest (container-id uint) (manifest-id uint))
  (let ((container (unwrap! (map-get? container-tracking { container-id: container-id }) ERR-NOT-FOUND))
        (manifest (unwrap! (map-get? cargo-manifests { manifest-id: manifest-id }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status container) "available") ERR-INVALID-STATUS)
    (asserts! (is-none (get assigned-manifest container)) ERR-INVALID-STATUS)

    (map-set container-tracking
      { container-id: container-id }
      (merge container { assigned-manifest: (some manifest-id), status: "assigned" })
    )

    (ok true)
  )
)

;; Update container location
(define-public (update-container-location (container-id uint) (new-location (string-ascii 50)))
  (let ((container (unwrap! (map-get? container-tracking { container-id: container-id }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-location) u0) ERR-INVALID-INPUT)

    (map-set container-tracking
      { container-id: container-id }
      (merge container { current-location: new-location, last-updated: block-height })
    )

    (ok true)
  )
)

;; Complete delivery
(define-public (complete-delivery (manifest-id uint))
  (let ((manifest (unwrap! (map-get? cargo-manifests { manifest-id: manifest-id }) ERR-NOT-FOUND)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status manifest) "scheduled") ERR-INVALID-STATUS)

    (map-set cargo-manifests
      { manifest-id: manifest-id }
      (merge manifest { status: "delivered" })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-cargo-manifest (manifest-id uint))
  (map-get? cargo-manifests { manifest-id: manifest-id })
)

(define-read-only (get-transportation-hub (hub-id uint))
  (map-get? transportation-hubs { hub-id: hub-id })
)

(define-read-only (get-freight-vehicle (vehicle-id uint))
  (map-get? freight-vehicles { vehicle-id: vehicle-id })
)

(define-read-only (get-transportation-schedule (schedule-id uint))
  (map-get? transportation-schedules { schedule-id: schedule-id })
)

(define-read-only (get-container-tracking (container-id uint))
  (map-get? container-tracking { container-id: container-id })
)

(define-read-only (get-freight-stats)
  {
    total-manifests: (- (var-get next-manifest-id) u1),
    total-hubs: (- (var-get next-hub-id) u1),
    total-vehicles: (- (var-get next-vehicle-id) u1),
    total-schedules: (- (var-get next-schedule-id) u1),
    total-containers: (- (var-get next-container-id) u1)
  }
)
