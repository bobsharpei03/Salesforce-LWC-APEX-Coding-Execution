import { LightningElement, api } from 'lwc';

export default class WizardStep1 extends LightningElement {
    @api stepData = {};

    accountName = '';
    industry = '';

    industryOptions = [
        { label: 'Technology', value: 'Technology' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Retail', value: 'Retail' },
        { label: 'Healthcare', value: 'Healthcare' }
    ];

    connectedCallback() {
        if (this.stepData) {
            this.accountName = this.stepData.accountName || '';
            this.industry = this.stepData.industry || '';
        }
    }

    handleChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    handleNext() {
        if (!this.accountName) {
            this.showError('Account Name is required.');
            return;
        }

        this.dispatchEvent(new CustomEvent('next', {
            detail: {
                step: 1,
                data: {
                    accountName: this.accountName,
                    industry: this.industry
                }
            }
        }));
    }

    showError(msg) {
        this.dispatchEvent(
            new CustomEvent('error', { detail: msg })
        );
    }
}
