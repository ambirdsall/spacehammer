(local is (require :spacehammer.lib.testing.assert))

(local {: menu!
        : action!
        : config
        : normalize-key-path} (require :spacehammer.forge))
(local {: hide-display-numbers} (require :spacehammer.windows))

(describe
 "Forge: config builder functions"
 (fn []
    (it "normalizes keypaths"
        (fn []
           (is.structurally-eq? (normalize-key-path "abc") [{:key :a} {:key :b} {:key :c}])
           (is.structurally-eq? (normalize-key-path ["de" {:key :f}]) [{:key :d} {:key :e} {:key :f}])
           (is.structurally-eq? (normalize-key-path ["gh" {:key :i :mods [:shift]}]) [{:key :g} {:key :h} {:key :i :mods [:shift]}])
           (is.structurally-eq? (normalize-key-path {:key :f}) [{:key :f}])
           ))

    (it "mutates the config object"
        (fn []
           (is.structurally-eq?
            {:title "Main Menu"
             :items []
             :enter hide-display-numbers
             :exit hide-display-numbers
             :keys []
             :apps []}
            config)

           (menu! :t "Test menu")
           (is.structurally-eq?
            {:title "Main Menu"
             :items [{:title "Test menu" :key :t :items []}]
             :enter hide-display-numbers
             :exit hide-display-numbers
             :keys []
             :apps []}
            config)
           (menu! :dnt "Deeply-nested test menu")
           (is.structurally-eq?
            {:title "Main Menu"
             :items [{:title "Test menu"
                      :key :t
                      :items []}
                     {:title "+prefix"
                      :key :d
                      :items [{:title "+prefix"
                               :key :n
                               :items [{:title "Deeply-nested test menu"
                                        :key :t
                                        :items []}]}]}]
             :enter hide-display-numbers
             :exit hide-display-numbers
             :keys []
             :apps []}
            config)))))
