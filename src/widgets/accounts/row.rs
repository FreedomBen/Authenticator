use gtk::{gdk, glib, prelude::*, subclass::prelude::*};

use crate::{models::Account, widgets::providers::ProviderRow};

mod imp {
    use std::cell::OnceCell;

    use adw::subclass::prelude::*;
    use gettextrs::gettext;
    use glib::{clone, subclass};

    use super::*;
    use crate::widgets::Window;

    #[derive(Default, gtk::CompositeTemplate, glib::Properties)]
    #[properties(wrapper_type = super::AccountRow)]
    #[template(resource = "/com/belmoussaoui/Authenticator/account_row.ui")]
    pub struct AccountRow {
        #[property(get, set, construct_only)]
        pub account: OnceCell<Account>,
        #[template_child]
        pub increment_btn: TemplateChild<gtk::Button>,
        #[template_child]
        pub copy_btn: TemplateChild<gtk::Button>,
        #[template_child]
        pub otp_label: TemplateChild<gtk::Label>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for AccountRow {
        const NAME: &'static str = "AccountRow";
        type Type = super::AccountRow;
        type ParentType = adw::ActionRow;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();

            klass.add_binding_action(
                gdk::Key::c,
                gdk::ModifierType::CONTROL_MASK,
                "account.copy-otp",
            );

            klass.install_action("account.copy-otp", None, |row, _, _| {
                row.account().copy_otp();
                let window = row.root().and_downcast::<Window>().unwrap();
                let toast = adw::Toast::new(&gettext("One-Time password copied"));
                toast.set_timeout(3);
                window.add_toast(toast);
            });
            klass.install_action("account.increment-counter", None, |row, _, _| {
                match row.account().increment_counter() {
                    Ok(_) => row.account().generate_otp(),
                    Err(err) => tracing::error!("Failed to increment the counter {err}"),
                };
            });
        }

        fn instance_init(obj: &subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    #[glib::derived_properties]
    impl ObjectImpl for AccountRow {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();
            let account = obj.account();
            account
                .bind_property("name", &*obj, "title")
                .sync_create()
                .build();

            account
                .bind_property("name", &*obj, "tooltip-text")
                .sync_create()
                .build();

            account
                .bind_property("code", &*self.otp_label, "label")
                .sync_create()
                .build();
            self.otp_label.set_direction(gtk::TextDirection::Ltr);

            // Only display the increment button if it is a HOTP account
            self.increment_btn
                .set_visible(account.provider().method().is_event_based());

            let key_controller = gtk::EventControllerKey::new();
            key_controller.connect_key_pressed(clone!(
                #[weak]
                obj,
                #[upgrade_or]
                glib::Propagation::Proceed,
                move |_, key, _, _| super::handle_arrow_key(&obj, key)
            ));
            self.copy_btn.add_controller(key_controller);
        }
    }
    impl WidgetImpl for AccountRow {}
    impl ListBoxRowImpl for AccountRow {}
    impl PreferencesRowImpl for AccountRow {}
    impl ActionRowImpl for AccountRow {}
}

glib::wrapper! {
    pub struct AccountRow(ObjectSubclass<imp::AccountRow>)
        @extends gtk::Widget, gtk::ListBoxRow, adw::PreferencesRow, adw::ActionRow,
        @implements gtk::Accessible, gtk::Actionable, gtk::Buildable, gtk::ConstraintTarget;
}

impl AccountRow {
    pub fn new(account: &Account) -> Self {
        glib::Object::builder().property("account", account).build()
    }

    pub fn focus_copy_btn(&self) {
        self.imp().copy_btn.grab_focus();
    }
}

fn handle_arrow_key(row: &AccountRow, key: gdk::Key) -> glib::Propagation {
    match key {
        gdk::Key::Down => {
            if let Some(next) = next_account_row(row) {
                next.focus_copy_btn();
                glib::Propagation::Stop
            } else {
                glib::Propagation::Proceed
            }
        }
        gdk::Key::Up => {
            if let Some(prev) = prev_account_row(row) {
                prev.focus_copy_btn();
                return glib::Propagation::Stop;
            }
            if let Some(window) = row.root().and_downcast::<crate::widgets::Window>() {
                let imp = window.imp();
                if imp.search_bar.is_search_mode() {
                    imp.search_entry.grab_focus();
                    return glib::Propagation::Stop;
                }
            }
            glib::Propagation::Proceed
        }
        _ => glib::Propagation::Proceed,
    }
}

fn next_account_row(current: &AccountRow) -> Option<AccountRow> {
    if let Some(next) = current.next_sibling().and_downcast::<AccountRow>() {
        return Some(next);
    }
    let provider_row = current
        .ancestor(ProviderRow::static_type())
        .and_downcast::<ProviderRow>()?;
    let mut sibling = provider_row.next_sibling();
    while let Some(widget) = sibling {
        if let Some(pr) = widget.downcast_ref::<ProviderRow>()
            && let Some(first) = pr.first_account_row()
        {
            return Some(first);
        }
        sibling = widget.next_sibling();
    }
    None
}

fn prev_account_row(current: &AccountRow) -> Option<AccountRow> {
    if let Some(prev) = current.prev_sibling().and_downcast::<AccountRow>() {
        return Some(prev);
    }
    let provider_row = current
        .ancestor(ProviderRow::static_type())
        .and_downcast::<ProviderRow>()?;
    let mut sibling = provider_row.prev_sibling();
    while let Some(widget) = sibling {
        if let Some(pr) = widget.downcast_ref::<ProviderRow>()
            && let Some(last) = pr.last_account_row()
        {
            return Some(last);
        }
        sibling = widget.prev_sibling();
    }
    None
}
