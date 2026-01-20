# Library Book Lending Smart Contract

A decentralized library management system for tracking book inventory and lending.

## Features

- Book catalog management
- Borrowing and return tracking
- Copy availability checking
- User borrowing history
- Due date management

## Contract Functions

### Public Functions

- `add-book` - Add new book to library (owner only)
- `borrow-book` - Borrow an available book
- `return-book` - Return a borrowed book
- `add-copies` - Add more copies of existing book (owner only)

### Read-Only Functions

- `get-book` - Get book details
- `get-loan` - Get loan details
- `is-available` - Check if book has available copies
- `get-user-active-loans` - Get user's current active loans
- `get-user-total-borrows` - Get user's total borrowing history
- `get-book-nonce` - Get current book counter

## Usage

Deploy with Clarinet to enable decentralized library management.