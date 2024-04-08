(local {: hide-display-numbers} (require :spacehammer.windows))

;; A set of functions for adding new submenus and actions to the spacehammer modal, along
;; with their keybindings, "a la carte": i.e. without having to manually maintain a large,
;; nested data structure.

;; we who are about to be mutated salute you
(local config {:title "Main Menu"
               :items []
               :keys []
               :enter hide-display-numbers
               :exit  hide-display-numbers
               :apps []})

(local activate-modal-action "spacehammer.lib.modal:activate-modal")

;; TODO auto-shift capitals, i.e. "aB" -> [{:key :a} {:key :b :mods [:shift]}]
(fn normalize-key-path [key-path-string-or-table]
  "Returns a normalized key path. A normalized key path is a list of key objects, where
  each is a table defining a key stroke; for example [{:key :a} {:key :c :mods [:ctrl]}]
  for 'a' followed by 'C-c'.

`key-path-string-or-table' can either be a string or a list containing key objects and/or
strings. Strings will be split character by character, with each being wrapped in a key
object; for example 'abc' becomes [{:key :a} {:key :b} {:key :c}]; because of this,
keys which are not unmodified alphanumeric characters can only be represented with key
objects (for example, {:key :space} or {:key :c :mods [:cmd :ctrl]})."
  (fn normalize [key-path acc]
    (case (type key-path)
      :string (each [s (string.gmatch key-path ".")] (table.insert acc {:key s}))
      :table (case key-path
               {:key k} (table.insert acc key-path)
               [_] (each [_ key (ipairs key-path)] (normalize key acc))))
    acc)
  (normalize key-path-string-or-table []))

(fn empty-default-submenu [{: key : mods}]
  "Returns a new instance of an empty menu, suitable for dynamically inserting into an
  undefined intermediary key in a longer menu! or action! prefix."
  {:title "+prefix"
   : key
   : mods
   :items []})

(fn empty-default-app-config [app-name]
  "Returns a new instance of an empty app config table."
  {:key app-name
   :keys []
   :items []})

;; TODO make mods comparison order-independent
(fn same-keybind? [a b]
  "Predicate for identical keybinds for a menu item (submenu or action). Arguments with
matching :key and :mods values return true."
  (and (= a.key b.key)
       (= (and a.mods (table.unpack a.mods))
          (and b.mods (table.unpack b.mods)))
       (= (and a.mods (length a.mods))
          (and b.mods (length b.mods)))))

(fn find-or-create-submenu [key-object parent-menu ?prev-idx]
  "Returns a menu object in `parent-menu' at the key defined in `key-object', or errors if
an action is already defined for that key. If the requested submenu already exists, it
will be returned directly; if the requested submenu does not exist, a empty default
submenu will be created, inserted into `parent-menu', and returned."
  (match (next parent-menu.items ?prev-idx)
    ;; already an action there? straight to jail.
    (where (idx {: key : mods :action _})
           (same-keybind? {: key : mods} key-object)) (error "A submenu cannot be defined at a keypath which contains an action")
    ;; found it
    (where (idx menu-node)
           (same-keybind? menu-node key-object)) menu-node
    ;; if at first you don't succeed, try try again
    (idx menu-node) (find-or-create-submenu key-object parent-menu idx)
    ;; if at last you don't succeed, make a new empty submenu at the given key
    nil (let [new-submenu (empty-default-submenu key-object)]
          (table.insert parent-menu.items new-submenu)
          new-submenu)))

(fn find-or-create-binding [key-object keys-list ?prev-idx]
  "Returns an action object in `parent-menu' at the key defined in `key-object', or errors if
a menu is already defined for that key. If the requested action already exists, it
will be returned directly; if the requested action does not exist, a empty default
action will be created, inserted into `parent-menu', and returned."
  (match (next keys-list ?prev-idx)
    ;; found it
    (where (idx binding)
           (same-keybind? binding key-object)) binding
    ;; if at first you don't succeed, try try again
    (idx binding) (find-or-create-binding key-object keys-list idx)
    ;; if at last you don't succeed, make a new empty binding at the given key
    nil (let [{: key : mods} key-object
              new-binding {: key : mods}]
          (table.insert keys-list new-binding)
          new-binding)))

(fn find-or-create-action [key-object parent-menu ?prev-idx]
  "Returns an action object in `parent-menu' at the key defined in `key-object', or errors if
a menu is already defined for that key. If the requested action already exists, it
will be returned directly; if the requested action does not exist, a empty default
action will be created, inserted into `parent-menu', and returned."
  (match (next parent-menu.items ?prev-idx)
    ;; already a menu there? straight to jail.
    (where (idx {: key : mods :items _})
           (same-keybind? {: key : mods} key-object)) (error "An action cannot be defined at a keypath which contains a submenu")
    ;; found it
    (where (idx action-node)
           (same-keybind? action-node key-object)) action-node
    ;; if at first you don't succeed, try try again
    (idx action-node) (find-or-create-action key-object parent-menu idx)
    ;; if at last you don't succeed, make a new empty action at the given key
    nil (let [{: key : mods} key-object
              ;; we can rely on `title' and `action' to be immediately provided
              new-action {: key : mods}]
          (table.insert parent-menu.items new-action)
          new-action)))

(fn find-or-create-parent-menu [prefix-key-path ?parent-menu]
  "Given a normalized key-path `prefix-key-path' and optionally a `?parent-menu', walks
`?parent-menu' (by default, the config object) and returns the submenu at the final key of
`prefix-key-path'. Any missing submenus will be created on the fly; if any action is
encountered within `prefix-key-path', an error will be raised.

Assumes that `prefix-key-path' is the full intended path of the parent menu: calling code
using this to ensure that an appropriate parent menu is defined for some action or submenu
is responsible for providing only the parent menu's segment of the key-path."
  (var parent-menu (or ?parent-menu config))
  (each [_ key (ipairs prefix-key-path)]
    (let [next-parent (find-or-create-submenu key parent-menu)]
      (set parent-menu next-parent)))
  parent-menu)

(fn separate-out-last-item [list]
  "Returns two values: the first being a new list with every item from `list' except the
last one, and the second being that last item."
  (let [len (length list)]
    (values (icollect [idx item (ipairs list)] (if (not= idx len) item))
            (. list len))))

(fn set-normalized-menu [key-path title options ?top-level-menu]
  "Defines or renames a new menu item within `?top-level-menu' (by default, `config'), at
  `key-path'. Any intermediary menus in `key-path' which do not already exist will be
  created with the default title of `+prefix'."
  ;; if the user provides invalid options, error before executing any potentially
  ;; destructive mutations
  (if options
      (each [key _ (pairs options)]
        (case key
          :enter nil
          :exit nil
          _ (error (.. "Attempted to define unknown menu option " key)))))

  (let [(prefix-key-path key-object) (separate-out-last-item key-path)
        parent-menu (find-or-create-parent-menu prefix-key-path ?top-level-menu)
        menu (find-or-create-submenu key-object parent-menu)]
    (tset menu :title title)
    (if options
        (each [key value (pairs options)]
          (tset menu key value)))
    menu))

(fn set-normalized-action [key-path title action ?top-level-menu]
  "Defines or renames a new action within `?top-level-menu' (by default, `config'), at
  `key-path'. Any intermediary menus in `key-path' which do not already exist will be
  created with the default title of `+prefix'."
  (let [(prefix-key-path key-object) (separate-out-last-item key-path)
        parent-menu (find-or-create-parent-menu prefix-key-path ?top-level-menu)
        action-node (find-or-create-action key-object parent-menu)]
    (tset action-node :title title)
    (tset action-node :action action)
    action-node))

;; TODO write docstring
(fn find-or-create-app-config [app-name ?prev-idx]
  ""
  (match (next config.apps ?prev-idx)
    ;; found it
    (where (idx app-node)
           (= app-node.key app-name)) app-node
    ;; if at first you don't succeed, try try again
    (idx app-node) (find-or-create-app-config app-name idx)
    ;; if at last you don't succeed, make a new config table for app-name
    nil (let [new-app-config (empty-default-app-config app-name)]
          (table.insert config.apps new-app-config)
          new-app-config)))

(fn clear-leader-keys []
  ;; iterate through config.keys
  ;; delete every node whose action is activating the modal
  (each [idx global-binding (ipairs config.keys)]
    (if (= global-binding.action activate-modal-action)
        (table.remove config.keys idx))))

;; TODO write docstring
(fn set-normalized-binding [key-path action top-level-config options]
  ""
  (let [[{: key : mods}] key-path
        binding (find-or-create-binding {: key : mods} top-level-config.keys)]
    (tset binding :key key)
    (tset binding :mods mods)
    (tset binding :action action)
    (if options
        (let [{: repeat} options]
          (tset binding :repeat repeat)))))

(fn app-config! [app-name options]
  "Configure application-scoped settings and callbacks for `app-name'. To define
  application-scoped actions, menus, or bindings, refer to `app-scoped-action!',
  `app-scoped-menu!', or `app-scoped-binding!', respectively."
  (let [app-conf (find-or-create-app-config app-name)
        {: activate : deactivate : launch} options]
    (tset app-conf :activate activate)
    (tset app-conf :deactivate deactivate)
    (tset app-conf :launch launch)))

(fn global-binding! [keys action options]
  (set-normalized-binding (normalize-key-path keys) action config options))

(fn leader! [...]
  "Set one or more leader key bindings for opening the modal UI of spacehammer actions.

If multiple keybindings are provided, multiple leader keys will be defined; each time its
called anew, all previously-defined leader key bindings are erased, which ensures that you
can edit your leader key(s) and reload without cluttering your global keymap."
  (clear-leader-keys)
  (each [_ key-path (ipairs [...])]
    (global-binding! key-path activate-modal-action)))

(fn menu! [keys title options]
  "Define a (possibly nested) menu in the pop-up modal interface. If the menu does not exist, it will be created; if it does, it will be modified based on your provided definition.

For the top-level menu, use an empty string for `keys`; for deeply nested
menus, provide the entire set of prefix keys required to access the menu. For
example, if there is a menu with keys `a` and another directly nested inside
at the keys `as`,  nesting a third inside the inner menu would require a three-
letter prefix matching the regex /as./. Any nonexistent intermediary submenus will be created with the default title, `+prefix`.

The `options` argument accepts a table for other table options like `:enter` and `:exit`."
  (set-normalized-menu (normalize-key-path keys) title options))

(fn action! [keys title action]
  "Define a new action within the popup modal interface.

The `keys` argument accepts either a string (e.g. for an action bound to `k` within a
submodal bound to `as`, the `keys` argument should be the string `ask`; any missing menus
will be automatically created) or a list, which can contain either strings or tables (e.g.
for a sibling action bound to Command-g, the `keys` argument should be `[:a :s {:mods
[:cmd] :key :g}]`)."
  (set-normalized-action (normalize-key-path keys) title action))

(fn app-scoped-binding! [app-name keys action options]
  (set-normalized-binding
   (normalize-key-path keys)
   action
   (find-or-create-app-config app-name)
   options))

(fn app-scoped-menu! [app-name keys title options]
  (set-normalized-menu (normalize-key-path keys) title options (find-or-create-app-config app-name)))

(fn app-scoped-action! [app-name keys title action]
  (set-normalized-action (normalize-key-path keys) title action (find-or-create-app-config app-name)))

;; export for use in other files
{: menu!
 : action!
 : leader!
 : global-binding!
 : app-scoped-menu!
 : app-scoped-action!
 : app-scoped-binding!
 : config
 : normalize-key-path}
