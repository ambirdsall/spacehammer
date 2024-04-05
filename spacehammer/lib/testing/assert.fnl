(local exports {})

(fn exports.eq?
  [actual expected message]
  (assert (= actual expected) (.. message " instead got " (hs.inspect actual))))

(fn exports.not-eq?
  [first second message]
  (assert (not= first second) (.. message " instead both were " (hs.inspect first))))

(fn exports.ok?
  [actual message]
  (assert (= (not (not actual)) true) (.. message " instead got " (hs.inspect actual))))

(fn structurally-eq?
  [actual expected]
  "Compares two tables for structural equality; that is, if every key of `actual' is
present in `expected' and associated with identical values, they are considered equal. It
is a deep comparison; nested tables are checked recursively."
  (case [(type actual) (type expected)]
    [:table :table] :pass
    [_ _] (error "structurally-eq? can only compare two tables"))

  (each [key expected-value (pairs expected)]
    (let [actual-value (. actual key)]
      (var inequality-detected? false)
      (case [(type actual-value) (type expected-value)]
        [:table :table] (set inequality-detected? (not (structurally-eq? actual-value expected-value)))
        [:table _] (set inequality-detected? true)
        [_ :table] (set inequality-detected? true)
        [_ _] (set inequality-detected? (not= actual-value expected-value)))
      (if inequality-detected?
          (lua "return false"))))
    true)

(fn exports.structurally-eq?
  [actual expected]
  "Asserts structural equality of tables; that is, if the tables have identical keys with
  identical values, they are considered equal."
  (assert
   (and (structurally-eq? actual expected) (structurally-eq? expected actual))
   (.. "expected " (hs.inspect expected) " but instead got " (hs.inspect actual))))

(fn exports.structural-subset?
  [actual expected]
  "Asserts one-way structural equality of tables; that is, if every key of `expected' exists
  in `actual' and is associated with the same value, they are considered equal. There may
  be additional unspecified items in `actual'."
  (assert (structurally-eq? actual expected)
          (.. "expected " (hs.inspect expected) " but instead got " (hs.inspect actual))))

exports
