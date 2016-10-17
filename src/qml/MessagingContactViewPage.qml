/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


import QtQuick 2.2
import QtContacts 5.0

import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3 as Popups
import Ubuntu.Contacts 0.1

import Ubuntu.AddressBook.Base 0.1
import Ubuntu.AddressBook.ContactView 0.1
import Ubuntu.AddressBook.ContactShare 0.1

ContactViewPage {
    id: root
    objectName: "contactViewPage"

    readonly property string contactEditorPageURL: Qt.resolvedUrl("MessagingContactEditorPage.qml")
    property string addPhoneToContact: ""
    property var contactListPage: null
    model: null

    function addPhoneToContactImpl(contact, phoneNumber)
    {
        var detailSourceTemplate = "import QtContacts 5.0; PhoneNumber{ number: \"" + phoneNumber.trim() + "\" }"
        var newDetail = Qt.createQmlObject(detailSourceTemplate, contact)
        if (newDetail) {
            contact.addDetail(newDetail)
            mainStack.addPageToCurrentColumn(root,
                                             root.contactEditorPageURL,
                                             { model: root.model,
                                               contact: contact,
                                               initialFocusSection: "phones",
                                               newDetails: [newDetail],
                                               contactListPage: root.contactListPage })
            root.addPhoneToContact = ""
        } else {
            console.warn("Fail to create phone number detail")
        }
    }

    headerActions: [
        Action {
            objectName: "share"
            text: i18n.tr("Share")
            iconName: "share"
            visible: root.editable
            onTriggered: {
                pageStack.addPageToCurrentColumn(root, contactShareComponent,
                               { contactModel: root.model,
                                 contacts: [root.contact] })
            }
        },
        Action {
            objectName: "edit"
            text: i18n.tr("Edit")
            iconName: "edit"
            visible: root.editable
            onTriggered: {
                pageStack.addPageToCurrentColumn(root, contactEditorPageURL,
                               { model: root.model,
                                 contact: root.contact,
                                 contactListPage: root.contactListPage })
            }
        }
    ]

    extensions: ContactDetailSyncTargetView {
        contact: root.contact
        anchors {
            left: parent.left
            right: parent.right
        }
        height: implicitHeight
    }


    Component {
        id: contactShareComponent
        ContactSharePage {}
    }

    Component {
        id: contactModelComponent

        ContactModel {
            id: contactModelHelper

            manager: (typeof(QTCONTACTS_MANAGER_OVERRIDE) !== "undefined") &&
                      (QTCONTACTS_MANAGER_OVERRIDE != "") ? QTCONTACTS_MANAGER_OVERRIDE : "galera"
            autoUpdate: false
            // make sure that the model is empty (no extra contact loaded)
            filter: InvalidFilter {}
        }
    }

    onActionTrigerred: {
        if ((action === "message") || (action == "default")) {
            if (root.contactListPage) {
                var list = root.contactListPage
                list.addRecipient(detail.value(0))
            } else {
                console.warn("Action message without contactList")
                var properties = {'participantIds': [detail.value(0)]}
                mainView.startChat(properties)
                return
            }
        } else {
            Qt.openUrlExternally(("%1:%2").arg(action).arg(detail.value(0)))
        }
        pageStack.removePages(root)
    }
    onContactRemoved: pageStack.removePages(root)
    onContactFetched: {
        root.contact = contact
        if (root.active && root.addPhoneToContact != "") {
            root.addPhoneToContactImpl(contact, root.addPhoneToContact)
            root.addPhoneToContact = ""
        }
    }

    onActiveChanged: {
        if (active && root.contact && root.addPhoneToContact != "") {
            root.addPhoneToContactImpl(contact, root.addPhoneToContact)
            root.addPhoneToContact = ""
        }
    }

    Component.onCompleted: {
        if (!root.model && root.editable) {
            root.model = contactModelComponent.createObject(root)
        }
    }
}
