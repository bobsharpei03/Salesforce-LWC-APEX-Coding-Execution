import { LightningElement, api } from 'lwc';

export default class WizardStep2 extends LightningElement {
    @api stepData = {};

    firstName = '';
    lastName = '';
    email = '';

    connectedCallback() {
        if (this.stepData) {
            this.firstName = this.stepData.firstName || '';
            this.lastName = this.stepData.lastName || '';
            this.email = this.stepData.email || '';
        }
    }

    handleChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    handleNext() {
        if (!this.lastName) {
            this.showError('Last Name is required.');
            return;
        }

        if (!this.email) {
            this.showError('Email is required.');
            return;
        }

        this.dispatchEvent(new CustomEvent('next', {
            detail: {
                step: 2,
                data: {
                    firstName: this.firstName,
                    lastName: this.lastName,
                    email: this.email
                }
            }
        }));
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    showError(msg) {
        this.dispatchEvent(
            new CustomEvent('error', { detail: msg })
        );
    }
}