use adw::prelude::*;
use gtk::{
    gio,
    glib::{self, clone},
    subclass::prelude::*,
};

use super::password_page::PasswordPage;
use crate::models::SETTINGS;

mod imp {
    use std::cell::Cell;

    use adw::subclass::prelude::*;

    use super::*;

    #[derive(gtk::CompositeTemplate, glib::Properties)]
    #[properties(wrapper_type = super::PreferencesWindow)]
    #[template(resource = "/com/belmoussaoui/Authenticator/preferences.ui")]
    pub struct PreferencesWindow {
        #[property(get, set, construct)]
        pub has_set_password: Cell<bool>,
        pub actions: gio::SimpleActionGroup,
        pub password_page: PasswordPage,
        #[template_child(id = "auto_lock_switch")]
        pub auto_lock: TemplateChild<adw::SwitchRow>,
        #[template_child(id = "download_favicons_switch")]
        pub download_favicons: TemplateChild<adw::SwitchRow>,
        #[template_child(id = "download_favicons_metered_switch")]
        pub download_favicons_metered: TemplateChild<adw::SwitchRow>,
        #[template_child(id = "lock_timeout_spin_btn")]
        pub lock_timeout: TemplateChild<adw::SpinRow>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for PreferencesWindow {
        const NAME: &'static str = "PreferencesWindow";
        type Type = super::PreferencesWindow;
        type ParentType = adw::PreferencesDialog;

        fn new() -> Self {
            let actions = gio::SimpleActionGroup::new();

            Self {
                has_set_password: Cell::default(), // Synced from the application
                password_page: PasswordPage::new(&actions),
                actions,
                auto_lock: TemplateChild::default(),
                download_favicons: TemplateChild::default(),
                download_favicons_metered: TemplateChild::default(),
                lock_timeout: TemplateChild::default(),
            }
        }

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    #[glib::derived_properties]
    impl ObjectImpl for PreferencesWindow {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();

            obj.setup_actions();
            obj.setup_widget();
        }
    }
    impl WidgetImpl for PreferencesWindow {}
    impl AdwDialogImpl for PreferencesWindow {}
    impl PreferencesDialogImpl for PreferencesWindow {}
}

glib::wrapper! {
    pub struct PreferencesWindow(ObjectSubclass<imp::PreferencesWindow>)
        @extends gtk::Widget, adw::Dialog, adw::PreferencesDialog;
}

impl PreferencesWindow {
    pub fn new() -> Self {
        glib::Object::new()
    }

    fn setup_widget(&self) {
        let imp = self.imp();

        SETTINGS
            .bind_download_favicons(&*imp.download_favicons, "active")
            .build();
        SETTINGS
            .bind_download_favicons_metred(&*imp.download_favicons_metered, "active")
            .build();
        SETTINGS.bind_auto_lock(&*imp.auto_lock, "active").build();
        SETTINGS
            .bind_auto_lock_timeout(&*imp.lock_timeout, "value")
            .build();

        imp.password_page
            .bind_property("has-set-password", self, "has-set-password")
            .sync_create()
            .bidirectional()
            .build();
    }

    fn setup_actions(&self) {
        let imp = self.imp();

        let show_password_page = gio::ActionEntry::builder("show_password_page")
            .activate(clone!(
                #[weak(rename_to = win)]
                self,
                move |_, _, _| {
                    win.push_subpage(&win.imp().password_page);
                }
            ))
            .build();

        let close_page = gio::ActionEntry::builder("close_page")
            .activate(clone!(
                #[weak(rename_to = win)]
                self,
                move |_, _, _| {
                    win.pop_subpage();
                }
            ))
            .build();

        imp.actions
            .add_action_entries([show_password_page, close_page]);

        self.insert_action_group("preferences", Some(&imp.actions));
    }
}
