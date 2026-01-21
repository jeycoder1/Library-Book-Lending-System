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

;; Public functions
;; #[allow(unchecked_data)]
(define-public (add-book 
  (title (string-ascii 100))
  (author (string-ascii 100))
  (isbn (string-ascii 20))
  (total-copies uint)
  (category (string-ascii 50)))
  (let
    (
      (book-id (var-get book-nonce))
    )
    (asserts! (is-librarian tx-sender) err-unauthorized)
    (asserts! (> total-copies u0) err-invalid-input)
    (map-set books book-id
      {
        title: title,
        author: author,
        isbn: isbn,
        total-copies: total-copies,
        available-copies: total-copies,
        added-by: tx-sender,
        category: category,
        rating-sum: u0,
        rating-count: u0
      }
    )
    (var-set book-nonce (+ book-id u1))
    (ok book-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (borrow-book (book-id uint) (loan-period uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
      (borrower tx-sender)
      (existing-loan (map-get? loans { book-id: book-id, borrower: borrower }))
      (due-date (+ stacks-block-height loan-period))
    )
    (asserts! (> (get available-copies book) u0) err-not-available)
    (asserts! (<= loan-period max-loan-period) err-invalid-input)
    (asserts! 
      (or 
        (is-none existing-loan)
        (get returned (unwrap-panic existing-loan))
      ) 
      err-already-borrowed
    )
    (map-set loans 
      { book-id: book-id, borrower: borrower }
      {
        borrowed-at: stacks-block-height,
        due-date: due-date,
        returned: false,
        return-date: u0
      }
    )
    (map-set books book-id
      (merge book { available-copies: (- (get available-copies book) u1) })
    )
    (map-set user-active-loans borrower (+ (get-user-active-loans borrower) u1))
    (map-set user-total-borrows borrower (+ (get-user-total-borrows borrower) u1))
    (var-set total-books-borrowed (+ (var-get total-books-borrowed) u1))
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (return-book (book-id uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
      (borrower tx-sender)
      (loan (unwrap! (map-get? loans { book-id: book-id, borrower: borrower }) err-not-borrowed))
      (is-late (> stacks-block-height (get due-date loan)))
    )
    (asserts! (not (get returned loan)) err-not-borrowed)
    (map-set loans 
      { book-id: book-id, borrower: borrower }
      (merge loan { 
        returned: true,
        return-date: stacks-block-height
      })
    )
    (map-set books book-id
      (merge book { available-copies: (+ (get available-copies book) u1) })
    )
    (map-set user-active-loans borrower (- (get-user-active-loans borrower) u1))
    (if is-late
      (var-set total-late-returns (+ (var-get total-late-returns) u1))
      true
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (reserve-book (book-id uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
      (reserver tx-sender)
      (existing-reservation (map-get? reservations { book-id: book-id, reserver: reserver }))
    )
    (asserts! 
      (or 
        (is-none existing-reservation)
        (not (get active (unwrap-panic existing-reservation)))
      )
      err-already-reserved
    )
    (map-set reservations 
      { book-id: book-id, reserver: reserver }
      {
        reserved-at: stacks-block-height,
        active: true
      }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (cancel-reservation (book-id uint))
  (let
    (
      (reserver tx-sender)
      (reservation (unwrap! (map-get? reservations { book-id: book-id, reserver: reserver }) err-no-reservation))
    )
    (asserts! (get active reservation) err-no-reservation)
    (map-set reservations 
      { book-id: book-id, reserver: reserver }
      (merge reservation { active: false })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (rate-book (book-id uint) (rating uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
      (rater tx-sender)
      (existing-rating (map-get? user-ratings { book-id: book-id, rater: rater }))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-input)
    (asserts! (is-none existing-rating) err-rating-exists)
    (map-set user-ratings { book-id: book-id, rater: rater } rating)
    (map-set books book-id
      (merge book {
        rating-sum: (+ (get rating-sum book) rating),
        rating-count: (+ (get rating-count book) u1)
      })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-rating (book-id uint) (new-rating uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
      (rater tx-sender)
      (old-rating (unwrap! (map-get? user-ratings { book-id: book-id, rater: rater }) err-not-found))
    )
    (asserts! (and (>= new-rating u1) (<= new-rating u5)) err-invalid-input)
    (map-set user-ratings { book-id: book-id, rater: rater } new-rating)
    (map-set books book-id
      (merge book {
        rating-sum: (+ (- (get rating-sum book) old-rating) new-rating)
      })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (add-copies (book-id uint) (additional-copies uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
    )
    (asserts! (is-librarian tx-sender) err-unauthorized)
    (asserts! (> additional-copies u0) err-invalid-input)
    (map-set books book-id
      (merge book {
        total-copies: (+ (get total-copies book) additional-copies),
        available-copies: (+ (get available-copies book) additional-copies)
      })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (grant-librarian-permission (user principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (map-set librarian-permissions user true)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (revoke-librarian-permission (user principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (map-set librarian-permissions user false)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (remove-book (book-id uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
    )
    (asserts! (is-librarian tx-sender) err-unauthorized)
    (asserts! (is-eq (get available-copies book) (get total-copies book)) err-not-available)
    (map-delete books book-id)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (extend-loan (book-id uint) (additional-blocks uint))
  (let
    (
      (borrower tx-sender)
      (loan (unwrap! (map-get? loans { book-id: book-id, borrower: borrower }) err-not-borrowed))
    )
    (asserts! (not (get returned loan)) err-not-borrowed)
    (asserts! (<= additional-blocks u500) err-invalid-input)
    (map-set loans 
      { book-id: book-id, borrower: borrower }
      (merge loan { 
        due-date: (+ (get due-date loan) additional-blocks)
      })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (update-book-info 
  (book-id uint)
  (title (string-ascii 100))
  (author (string-ascii 100))
  (category (string-ascii 50)))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
    )
    (asserts! (is-librarian tx-sender) err-unauthorized)
    (map-set books book-id
      (merge book {
        title: title,
        author: author,
        category: category
      })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (reduce-copies (book-id uint) (copies-to-remove uint))
  (let
    (
      (book (unwrap! (map-get? books book-id) err-not-found))
    )
    (asserts! (is-librarian tx-sender) err-unauthorized)
    (asserts! (>= (get available-copies book) copies-to-remove) err-not-available)
    (asserts! (>= (get total-copies book) copies-to-remove) err-invalid-input)
    (map-set books book-id
      (merge book {
        total-copies: (- (get total-copies book) copies-to-remove),
        available-copies: (- (get available-copies book) copies-to-remove)
      })
    )
    (ok true)
  )
)