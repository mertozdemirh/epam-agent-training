import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createLead from '@salesforce/apex/LeadCaptureController.createLead';

import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const LEAD_SOURCE_OPTIONS = [
    { label: 'Web',              value: 'Web' },
    { label: 'Phone Inquiry',    value: 'Phone Inquiry' },
    { label: 'Partner Referral', value: 'Partner Referral' },
    { label: 'Other',            value: 'Other' }
];

export default class LeadCaptureForm extends LightningElement {
    @api recordId;

    @track firstName    = '';
    @track lastName     = '';
    @track email        = '';
    @track phone        = '';
    @track company      = '';
    @track leadSource   = '';
    @track notes        = '';
    @track isLoading    = false;

    leadSourceOptions = LEAD_SOURCE_OPTIONS;

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD] })
    wiredAccount({ data, error }) {
        if (data) {
            this.company = getFieldValue(data, ACCOUNT_NAME_FIELD) || '';
        } else if (error) {
            console.error('Error loading Account:', error);
        }
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    handleSubmit() {
        if (!this.validateForm()) return;

        this.isLoading = true;

        createLead({
            firstName:       this.firstName,
            lastName:        this.lastName,
            email:           this.email,
            phone:           this.phone,
            company:         this.company,
            leadSource:      this.leadSource,
            notes:           this.notes,
            sourceAccountId: this.recordId
        })
        .then(() => {
            const leadName = [this.firstName, this.lastName].filter(Boolean).join(' ');
            this.dispatchEvent(new ShowToastEvent({
                title:   'Success',
                message: `Lead "${leadName}" created successfully!`,
                variant: 'success'
            }));
            this.resetForm();
        })
        .catch(error => {
            const message = error?.body?.message || error?.message || 'An unknown error occurred.';
            this.dispatchEvent(new ShowToastEvent({
                title:   'Error creating Lead',
                message: message,
                variant: 'error',
                mode:    'sticky'
            }));
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    validateForm() {
        let isValid = true;

        // Trigger native LWC validation (required, type="email", etc.)
        this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea').forEach(field => {
            if (!field.reportValidity()) {
                isValid = false;
            }
        });

        if (!isValid) return false;

        // Additional email regex validation
        if (this.email && !EMAIL_REGEX.test(this.email)) {
            this.dispatchEvent(new ShowToastEvent({
                title:   'Invalid Email',
                message: 'Please enter a valid email address.',
                variant: 'error'
            }));
            return false;
        }

        // Notes length guard
        if (this.notes && this.notes.length > 500) {
            this.dispatchEvent(new ShowToastEvent({
                title:   'Notes Too Long',
                message: 'Notes must be 500 characters or fewer.',
                variant: 'error'
            }));
            return false;
        }

        return true;
    }

    resetForm() {
        this.firstName  = '';
        this.lastName   = '';
        this.email      = '';
        this.phone      = '';
        this.leadSource = '';
        this.notes      = '';
        // Keep company auto-populated from Account
    }
}
