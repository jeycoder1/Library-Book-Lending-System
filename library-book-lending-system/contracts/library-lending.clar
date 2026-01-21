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