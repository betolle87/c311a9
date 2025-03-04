#lang racket
;Replace your higher-order function representations of continuations with a tagged-list data structure representation. Remember,
;if you add (else (k v)) as the last line of your match, you can test each transformation one at a time. 

(define make-inner-mult
  (lambda (x1^ k^)
    `(make-inner-mult ,x1^  ,k^)
    #;(lambda (v) (apply-k k^ (* x1^ v)))))

(define make-outer-mult
  (lambda  (x2^ env^ k^)
    `(make-outer-mult ,x2^ ,env^ ,k^)
     #;(lambda (v) (value-of-cps x2^ env^ (make-inner-mult v k^)))))

(define make-inner-sub1
  (lambda (k^)
    `(make-inner-sub1 ,k^)
    #;(lambda (v) (apply-k k^ (sub1 v)))))

(define make-inner-zero 
  (lambda (k^)
    `(make-inner-zero ,k^)
    #; (lambda (v) (apply-k k^ (zero? v)))))
  
(define make-inner-if
  (lambda (conseq^ alt^ env^ k^)
    `(make-inner-if ,conseq^ ,alt^ ,env^ ,k^)
   #;  (lambda (v) (if v (value-of-cps conseq^ env^ k^)
                      (value-of-cps alt^ env^ k^)))))

(define make-inner-let
  (lambda (body^ env^ k^)
    `(make-inner-let ,body^ ,env^ ,k^)
    #; (lambda (v) (value-of-cps body^ (extend-env env^ v) k^))))

(define make-inner-throw
  (lambda(k-exp-v^)
    `(make-inner-throw ,k-exp-v^)
    #; (lambda (v)
    (k-exp-v^ v))))

(define make-outer-throw
  (lambda (v-exp^ env^)
    `(make-outer-throw ,v-exp^ ,env^)
     #;(lambda (v) (value-of-cps v-exp^ env^ (make-inner-throw v)))))

(define make-inner-app
  (lambda (clos^ k^)
    `(make-inner-app ,clos^ ,k^)
    #; (lambda (v) (apply-closure clos^ v k^))))

(define make-outer-app
  (lambda (rand^ env^ k^)
    `(make-outer-app ,rand^ ,env^ ,k^)
    #; (lambda (v) (value-of-cps rand^ (extend-env env^ (make-inner-app v k^)) k^)))) 
    
(define empty-env
  (lambda ()
    `(empty-env)))
 
(define empty-k
  (lambda ()
    (lambda (v)
      v)))

(define apply-env
  (lambda (env y k^)
    (match env
      (`(empty-env) (error 'value-of "unbound identifier"))
      (`(extend-env ,env^ ,v^) (if (zero? y) (apply-k k^ v^) (apply-env env^ (sub1 y) k^)))))) 

(define extend-env
  (lambda (env^ v^)
    `(extend-env ,env^ ,v^)))

(define make-closure
  (lambda (body env)
    `(make-closure ,body ,env)))

(define apply-closure
  (lambda (clos a k)
    (match clos
      (`(make-closure ,body ,env) (value-of-cps body (extend-env env a) k)))))

(define apply-k
  (lambda (k v)
    (match k
      [`(make-inner-mult ,x1^  ,k^) (apply-k k^ (* x1^ v))]
      [`(make-outer-mult ,x2^ ,env^ ,k^) (value-of-cps x2^ env^ (make-inner-mult v k^))]
      [`(make-inner-sub1 ,k^) (apply-k k^ (sub1 v))]
      [`(make-inner-zero ,k^) (apply-k k^ (zero? v))]
      [`(make-inner-if ,conseq^ ,alt^ ,env^ ,k^) (if v (value-of-cps conseq^ env^ k^) (value-of-cps alt^ env^ k^))]
      [`(make-inner-let ,body^ ,env^ ,k^) (value-of-cps body^ (extend-env env^ v) k^)]
      [`(make-inner-throw ,k-exp-v^) (k-exp-v^ v)]
      [`(make-outer-throw ,v-exp^ ,env^) (value-of-cps v-exp^ env^ (make-inner-throw v))]
      [`(make-inner-app ,clos^ ,k^) (apply-closure clos^ v k^)]
      [`(make-outer-app ,rand^ ,env^ ,k^) (value-of-cps rand^ (extend-env env^ (make-inner-app v k^)) k^)]
    (else (k v)))))


(define value-of-cps
  (lambda (expr env k)
    (match expr
      [`(const ,expr) (apply-k k expr)]
      [`(var ,y) (apply-env env y k)] 
      [`(mult ,x1 ,x2) (value-of-cps x1 env (make-outer-mult x2 env k))]
      [`(sub1 ,x)  (value-of-cps x env (make-inner-sub1 k))]
      [`(zero ,x)  (value-of-cps x env (make-inner-zero k))] 
      [`(if ,test ,conseq ,alt) (value-of-cps test env (make-inner-if  conseq alt env k))]
      [`(let ,e ,body) (value-of-cps e env (make-inner-let body env k))]
      ;fixed errors (ignore if you do not care
      ;just found error !X!. extending env w recur call doesnt make sense.
      ;also just realized there is not a let case in lex. Which is probably why test wasn't actually testing 
      ;[`(let ,e ,body) (value-of-cps e (!X! extend-env env (value-of-cps body (make-inner-let env k)(lambda (y) (extend-env env y)) k)) k)]
      ;another  error found here   -->        V     (cant still have lambdas  (guessing to pass continuation to env bc idk what other value is avaliable
      ;[`(letcc ,body) (value-of-cps body (lambda (y) (extend-env env y)) k)]               ^ worked so guessing the guess was correct
      [`(letcc ,body) (value-of-cps body (extend-env env k) k)] 
      [`(throw ,k-exp ,v-exp) (value-of-cps k-exp env (make-outer-throw v-exp env))] 
      [`(lambda ,body) (apply-k k (make-closure body env))]
      [`(app ,rator ,rand) (value-of-cps rator env (make-outer-app rand env k))])))
































(eqv? (value-of-cps '(const 7) (empty-env)(empty-k))
      7)

(eqv? (value-of-cps '(mult (const 7) (const 3)) (empty-env)(empty-k))
      21)
(eqv? (value-of-cps '(mult (const 7) (mult (const 3) (const 2))) (empty-env)(empty-k))
      42)

(eqv? (value-of-cps '(sub1 (const 7)) (empty-env)(empty-k))
      6)

(eqv? (value-of-cps '(zero (const 7)) (empty-env)(empty-k))
      #f)
(eqv? (value-of-cps '(zero (const 0)) (empty-env)(empty-k))
      #t)

(eqv? (value-of-cps '(if (zero (const 0)) (sub1 (const 2)) (const 9)) (empty-env) (empty-k))
      1)

(eqv? 
(value-of-cps '(if (zero (const 1)) (sub1 (const 2)) (sub1 (const 9))) (empty-env) (empty-k))
8)

(eqv?
(value-of-cps '(let (const 5) (var 0)) (empty-env)(empty-k))
5)

(eqv? 
(value-of-cps '(letcc (mult (const 2) (const 5))) (empty-env)(empty-k))
10)

(eqv?
(value-of-cps '(letcc (const 2)) (empty-env)(empty-k))
2)

(eqv?
(value-of-cps '(app (if (zero (const 1)) (lambda (var 0) (const 0)) (lambda (var 1))) (const 3)) (empty-env)(empty-k))
3)

