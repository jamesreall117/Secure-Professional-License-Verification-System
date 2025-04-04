;; status-tracking.clar
;; This contract monitors active/suspended status of licenses

(define-constant err-not-authorized (err u100))
(define-constant err-license-not-found (err u101))
(define-constant err-invalid-status (err u102))

;; Define license status types
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-SUSPENDED u2)
(define-constant STATUS-REVOKED u3)
(define-constant STATUS-EXPIRED u4)

;; Map to store license statuses
(define-map license-statuses
  { license-id: (string-ascii 20) }
  {
    status: uint,
    last-updated: uint,
    reason: (string-ascii 200),
    updated-by: principal
  }
)

;; Contract for license validation
(define-trait license-trait
  (
    (license-exists ((string-ascii 20)) (response bool uint))
  )
)

;; Contract for authority validation
(define-trait authority-trait
  (
    (is-authority (principal) (response bool uint))
  )
)

;; Update license status
(define-public (update-status
    (license-id (string-ascii 20))
    (new-status uint)
    (reason (string-ascii 200))
    (license-contract <license-trait>)
    (authority-contract <authority-trait>))
  (let
    ((authority-check (contract-call? authority-contract is-authority tx-sender))
     (license-check (contract-call? license-contract license-exists license-id)))
    (begin
      (asserts! (is-ok authority-check) err-not-authorized)
      (asserts! (is-eq (unwrap-panic authority-check) true) err-not-authorized)
      (asserts! (is-ok license-check) err-license-not-found)
      (asserts! (is-eq (unwrap-panic license-check) true) err-license-not-found)
      (asserts! (or (is-eq new-status STATUS-ACTIVE)
                   (is-eq new-status STATUS-SUSPENDED)
                   (is-eq new-status STATUS-REVOKED)
                   (is-eq new-status STATUS-EXPIRED))
               err-invalid-status)

      (map-set license-statuses
        { license-id: license-id }
        {
          status: new-status,
          last-updated: block-height,
          reason: reason,
          updated-by: tx-sender
        }
      )
      (ok true)
    )
  )
)

;; Get license status
(define-read-only (get-license-status (license-id (string-ascii 20)))
  (default-to
    {
      status: STATUS-ACTIVE,
      last-updated: u0,
      reason: "",
      updated-by: tx-sender
    }
    (map-get? license-statuses { license-id: license-id })
  )
)

;; Check if a license is active
(define-read-only (is-license-active (license-id (string-ascii 20)))
  (let
    ((status-data (get-license-status license-id)))
    (is-eq (get status status-data) STATUS-ACTIVE)
  )
)
