(local is (require :spacehammer.lib.testing.assert))

(fn errors? [test-fn]
  (is.eq? (pcall test-fn) false "expected an error"))

(describe
 "is.structurally-eq?"
 #(do
    (it "errors unless all arguments are tables"
        #(do
           (errors? #(is.structurally-eq? [1 2 3] :not-a-table "second arg not a table"))
           (errors? #(is.structurally-eq? :not-a-table [1 2 3] "first arg not a table"))
           (errors? #(is.structurally-eq? :not-a-table :also-not-a-table "neither arg is a table"))))

    (it "compares sequential tables"
        #(do
           (is.structurally-eq? [1 2 :three] [1 2 :three] "expected a match")
           (is.structurally-eq? {1 1 2 2 3 :three} [1 2 :three] "expected a match with different syntax")
           (errors? #(is.structurally-eq? [1 2] [2 1] "out of order"))
           (errors? #(is.structurally-eq? [1 2] [1 2 :three] "element missing from first"))
           (errors? #(is.structurally-eq? [1 2 :three] [1 2] "element missing from second"))))

    (it "compares associative tables"
        #(do
           (let [a 1]
             (is.structurally-eq? {:a 1} {: a} "expected {:a 1}"))
           (errors? #(is.structurally-eq? {:a 1 :b 2} {:a 1} "pair missing from second"))
           (errors? #(is.structurally-eq? {:a 1} {:a 1 :b 2} "pair missing from first"))))

    (it "recursively compares nested tables"
        #(do
           (is.structurally-eq? {:a [1 2] :b :scalar} {:a [1 2] :b :scalar} "expected a match")
           (errors? #(is.structurally-eq? {:a [1 2] :b :scalar} {:a [1 2 3] :b :scalar} "mismatch in inner list"))
           (is.structurally-eq? {:a {:inner [1 2]} :b :scalar} {:a {:inner [1 2]} :b :scalar} "expected a match")
           (errors? #(is.structurally-eq? {:a {:inner [1 2]} :b :scalar} {:a {:inner [1 2 3]} :b :scalar} "mismatch in inner list"))
           (errors? #(is.structurally-eq? {:a {:inner [1 2] :missing "pair"} :b :scalar} {:a {:inner [1 2]} :b :scalar} "extra key in inner table"))))))
