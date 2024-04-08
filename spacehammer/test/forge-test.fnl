(local is (require :spacehammer.lib.testing.assert))

(local {: menu!
        : action!
        : leader!
        : global-binding!
        : app-scoped-menu!
        : app-scoped-action!
        : app-scoped-binding!
        : config
        : normalize-key-path} (require :spacehammer.forge))
(local {: hide-display-numbers} (require :spacehammer.windows))

(fn reset-config! []
  (tset config :items [])
  (tset config :keys [])
  (tset config :apps []))

(fn dummy-action [])

(describe
 "Forge: config builder functions"
 (fn []
   (it "normalizes keypaths"
       (fn []
         (is.structurally-eq? (normalize-key-path "abc") [{:key :a} {:key :b} {:key :c}])
         (is.structurally-eq? (normalize-key-path ["de" {:key :f}]) [{:key :d} {:key :e} {:key :f}])
         (is.structurally-eq? (normalize-key-path ["gh" {:key :i :mods [:shift]}]) [{:key :g} {:key :h} {:key :i :mods [:shift]}])
         (is.structurally-eq? (normalize-key-path {:key :f}) [{:key :f}])))

   (it "adds menus to the config object"
       (fn []
         (reset-config!)
         (is.structurally-eq?
          config
          {:title "Main Menu"
           :items []
           :enter hide-display-numbers
           :exit hide-display-numbers
           :keys []
           :apps []})

         (menu! :t "Test menu")
         (is.structurally-eq?
          config
          {:title "Main Menu"
           :items [{:title "Test menu" :key :t :items []}]
           :enter hide-display-numbers
           :exit hide-display-numbers
           :keys []
           :apps []})

         (menu! :dnt "Deeply-nested test menu")
         (is.structurally-eq?
          config
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
           :apps []})))

   (it "adds actions to the config object"
       (fn []
         (reset-config!)
         (is.structurally-eq?
          config
          {:title "Main Menu"
           :items []
           :enter hide-display-numbers
           :exit hide-display-numbers
           :keys []
           :apps []})
         (menu! :t "Test menu pt II: Action Boogaloo")
         (action! {:key :space} "spacey action" "spacey-action")
         (action! :tt "testy action" dummy-action)
         (is.structurally-eq?
          config
          {:title "Main Menu"
           :items [{:title "Test menu pt II: Action Boogaloo"
                    :key :t
                    :items [{:title "testy action" :key :t :action dummy-action}]}
                   {:title "spacey action"
                    :key :space
                    :action "spacey-action"}]
           :enter hide-display-numbers
           :exit hide-display-numbers
           :keys []
           :apps []})))

   (it "sets the modal leader key"
     (fn []
       (reset-config!)
       (leader! {:mods [:alt] :key :space})
       (is.structurally-eq?
        config
        {:title "Main Menu"
         :items []
         :enter hide-display-numbers
         :exit hide-display-numbers
         :keys [{:mods [:alt]
                 :key :space
                 :action "spacehammer.lib.modal:activate-modal"}]
         :apps []})

       ;; multiple calls reset the leader key(s)
       (leader! {:mods [:cmd] :key :space})
       (is.structurally-eq?
        config
        {:title "Main Menu"
         :items []
         :enter hide-display-numbers
         :exit hide-display-numbers
         :keys [{:mods [:cmd]
                 :key :space
                 :action "spacehammer.lib.modal:activate-modal"}]
         :apps []})))

   (it "sets global bindings"
       (fn []
         (reset-config!)
         (global-binding! {:key :c :mods [:ctrl]} dummy-action)
         (is.structurally-eq?
          config
          {:title "Main Menu"
           :items []
           :enter hide-display-numbers
           :exit hide-display-numbers
           :apps []
           :keys [{:key :c :mods [:ctrl] :action dummy-action}]})

         ;; multiple calls using the same keys edit the existing binding, rather than
         ;; adding an additional binding with duplicate keys
         (global-binding! {:key :c :mods [:ctrl]} dummy-action {:repeat true})
         (is.structurally-eq?
          config
          {:title "Main Menu"
           :items []
           :enter hide-display-numbers
           :exit hide-display-numbers
           :apps []
           :keys [{:key :c :mods [:ctrl] :action dummy-action :repeat true}]})))

   (it "sets app-specific actions, menus, and bindings"
       (fn []
         (reset-config!)
         (app-scoped-action! "Test app" :t "Top-level app-scoped action" dummy-action)

         (app-scoped-menu! "Test app" :m "Application submenu")
         (app-scoped-action! "Test app" :mn "Explicitly nested app-scoped action" dummy-action)

         (app-scoped-action! "Other app" :mn "Implicitly nested app-scoped action" dummy-action)

         (app-scoped-binding! "Test app" {:key :c :mods [:ctrl]} dummy-action)
         (app-scoped-binding! "Test app" {:key :c :mods [:ctrl :shift]} dummy-action {:repeat true})

         (is.structurally-eq?
          config
          {:title "Main Menu"
           :items []
           :enter hide-display-numbers
           :exit hide-display-numbers
           :keys []
           :apps [{:key "Test app"
                   :keys [{:key :c :mods [:ctrl] :action dummy-action}
                          {:key :c :mods [:ctrl :shift] :action dummy-action :repeat true}]
                   :items [{:key :t
                            :title "Top-level app-scoped action"
                            :action dummy-action}
                           {:key :m
                            :title "Application submenu"
                            :items [{:key :n
                                     :title "Explicitly nested app-scoped action"
                                     :action dummy-action}]}]}
                  {:key "Other app"
                   :keys []
                   :items [{:key :m
                            :title "+prefix"
                            :items [{:key :n
                                     :title "Implicitly nested app-scoped action"
                                     :action dummy-action}]}]}]})))))
