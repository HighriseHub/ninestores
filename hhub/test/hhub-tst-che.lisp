;; -*- mode: common-lisp; coding: utf-8 -*-x
(in-package :hhub)

(defvar *golden-cache* (make-hash-table :test 'eql)) ;;stores (complex-number . closure)
(defparameter *golden-ratio* (/ (+ 1 (sqrt 5)) 2))  ;; φ ≈ 1.618
(defparameter *golden-angle* (* 2 pi (- *golden-ratio* 1)))  ;; 2π(φ - 1)

(defun hash-table-keys (ht)
  (let ((keys nil))
    (maphash
     #'(lambda (k v)
         (declare (ignore v))
         (push k keys))
     ht)
    keys))

(defun golden-rotate (z)
  "Rotates a complex number by the golden angle (~137.5 degrees)."
  (* z (exp (* #C(0 1) (* 2 pi (- (/ (sqrt 5) 2) 1))))))  ;; Rotation using golden ratio

(defun cache-function (fn key)
  "Stores a function (closure) in the cache with a golden-ratio rotated key."
  (setf (gethash key *golden-cache*) fn))


(defun retrieve-golden-nearest (query-z stored-points)
  "Find the nearest stored complex number to query-z in stored-points."
  (reduce (lambda (closest current)
            (if (< (abs (- query-z current)) (abs (- query-z closest)))
                current
                closest))
          stored-points))

(defun retrieve-nearest-function (query-z)
  "Find and execute the function closest to query-z."
  (let* ((stored-points (hash-table-keys *golden-cache*))
         (nearest (retrieve-golden-nearest (next-golden-number query-z) stored-points))
         (func (gethash nearest *golden-cache*)))
    
    (if func
        (funcall func)
        (format t "No function found near ~A~%" query-z))))

(defun rotate-golden-cache ()
  "Rotates all cached function keys by the golden ratio angle."
  (setf *golden-cache*
        (mapcar (lambda (item)
                  (cons (golden-rotate (car item)) (cdr item)))
                *golden-cache*)))

(defun goldencacheinit ()
  ;; Example Usage:
  
    ;; Store 10,000 functions in the golden spiral
    (loop for n from 1 to 10000 do
      (let ((cmplxnum (next-golden-number n)))
	(cache-function (lambda () (format t "Executing function with key  ~d" cmplxnum)) cmplxnum)))
      
    ;;(print "Before Golden Rotation:")
    ;;(print *golden-cache*)
    ;;(rotate-golden-cache)  ;; Rotate using the golden ratio
    ;;(print "After Golden Rotation:")
    ;;(print *golden-cache*)
    
    ;; Retrieve and execute the nearest function to (1+0i)
  ;;(retrieve-nearest-function (next-golden-number k))
  )

(defun next-golden-number (n)
  "Generate the nth complex number in the golden spiral sequence, seeded from z = 1 + 0i."
  (let* ((r (sqrt n))  ;; Radius grows as sqrt(n)
         (theta (* n *golden-angle*))  ;; Rotation by golden angle
         (x (* r (cos theta)))
         (y (* r (sin theta))))
    (complex x y)))  ;; Return complex number

;; Example usage:
;; (next-golden-number 1)  ;; Generates first point in the golden spiral
;; (next-golden-number 50000)  ;; Generates the 50000th point


(defun random-complex-in-disk (R)
  "Generate a uniformly random complex number within a disk of radius R."
  (let* ((theta (* 2 pi (random 1.0))) ; random angle in [0, 2π)
         (u (random 1.0))               ; random number in [0, 1)
         (r (* R (sqrt u)))             ; radius scaled by sqrt(u) for uniformity
         (x (* r (cos theta)))
         (y (* r (sin theta))))
    (complex x y)))

(defun generate-complex-otp (n)
  "Generate an n-digit OTP (n between 4 and 9) using a complex number approach.
It combines a random complex number (from a unit disk) with a time-based component."
  (unless (and (integerp n) (>= n 4) (<= n 9))
    (error "n must be an integer between 4 and 9."))
  (let* ((R 1.0)
         ;; Generate a random complex number within the unit disk.
         (z-rand (random-complex-in-disk R))
         ;; Get high-resolution time: get-internal-real-time returns ticks.
         (time-ticks (get-internal-real-time))
         (time-resolution (get-internal-real-time-resolution))
         (time-seconds (/ time-ticks time-resolution))
         ;; Use the fractional part of time as a number in [0,1)
         (fraction (mod time-seconds 1.0))
         ;; Represent time as a complex number (same value for real and imaginary parts)
         (z-time (complex fraction fraction))
         ;; Combine the randomness by multiplying the two complex numbers.
         (z (* z-rand z-time))
         ;; Shift the result so that the real and imaginary parts are positive.
         (x (+ (realpart z) 1.0))
         (y (+ (imagpart z) 1.0))
         ;; Combine the two components into a single number.
         (num (floor (+ (* x 1000) (* y 1000)))))
    ;; Ensure the number has exactly n digits by taking modulo 10^n and formatting with leading zeros.
    (let* ((modulus (expt 10 n))
           (otp (mod num modulus)))
      (format nil "~v,'0D" n otp))))

;; Example usage:
;;(format t "4-digit OTP: ~a~%" (generate-complex-otp 4))
;;(format t "6-digit OTP: ~a~%" (generate-complex-otp 6))
;;(format t "8-digit OTP: ~a~%" (generate-complex-otp 8))

;; does not work the way designed.
(defun get-internal-real-time-resolution ()
  (let ((start (get-internal-real-time)))
    (/ (- start (get-universal-time) )  ;; Calculate difference between two calls
       (random 10)))) ; Divide by a known small time interval
