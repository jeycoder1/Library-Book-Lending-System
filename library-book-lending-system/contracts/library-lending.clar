;; Library Book Lending Contract
;; Decentralized library management and book lending system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-not-available (err u102))
(define-constant err-already-borrowed (err u103))
(define-constant err-not-borrowed (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-overdue (err u106))
(define-constant err-already-reserved (err u107))
(define-constant err-no-reservation (err u108))
(define-constant err-rating-exists (err u109))
(define-constant max-loan-period u1000)

;; Data Variables
(define-data-var book-nonce uint u0)
(define-data-var total-books-borrowed uint u0)
(define-data-var total-late-returns uint u0)

;; Data Maps
(define-map books
  uint
  {
    title: (string-ascii 100),
    author: (string-ascii 100),
    isbn: (string-ascii 20),
    total-copies: uint,
    available-copies: uint,
    added-by: principal,
    category: (string-ascii 50),
    rating-sum: uint,
    rating-count: uint
  }
)

(define-map loans
  { book-id: uint, borrower: principal }
  {
    borrowed-at: uint,
    due-date: uint,
    returned: bool,
    return-date: uint
  }
)

(define-map reservations
  { book-id: uint, reserver: principal }
  {
    reserved-at: uint,
    active: bool
  }
)

(define-map user-active-loans principal uint)

(define-map user-total-borrows principal uint)

(define-map user-ratings
  { book-id: uint, rater: principal }
  uint
)

(define-map librarian-permissions principal bool)

;; Read-only functions
(define-read-only (get-book (book-id uint))
  (map-get? books book-id)
)

(define-read-only (get-loan (book-id uint) (borrower principal))
  (map-get? loans { book-id: book-id, borrower: borrower })
)

(define-read-only (is-available (book-id uint))
  (match (map-get? books book-id)
    book (> (get available-copies book) u0)
    false
  )
)

(define-read-only (get-user-active-loans (user principal))
  (default-to u0 (map-get? user-active-loans user))
)

(define-read-only (get-user-total-borrows (user principal))
  (default-to u0 (map-get? user-total-borrows user))
)

(define-read-only (get-book-nonce)
  (var-get book-nonce)
)

(define-read-only (get-reservation (book-id uint) (reserver principal))
  (map-get? reservations { book-id: book-id, reserver: reserver })
)

(define-read-only (is-overdue (book-id uint) (borrower principal))
  (match (map-get? loans { book-id: book-id, borrower: borrower })
    loan (and 
      (not (get returned loan))
      (> stacks-block-height (get due-date loan))
    )
    false
  )
)

(define-read-only (get-book-rating (book-id uint))
  (match (map-get? books book-id)
    book (if (> (get rating-count book) u0)
      (ok (/ (get rating-sum book) (get rating-count book)))
      (ok u0)
    )
    err-not-found
  )
)

(define-read-only (is-librarian (user principal))
  (or 
    (is-eq user contract-owner)
    (default-to false (map-get? librarian-permissions user))
  )
)

(define-read-only (get-total-books-borrowed)
  (var-get total-books-borrowed)
)

(define-read-only (get-total-late-returns)
  (var-get total-late-returns)
)