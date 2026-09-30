import { LightningElement, api } from 'lwc';

export default class WizardStep3 extends LightningElement {
    @api stepData = {};

    preferences = '';

    connectedCallback() {
        if (this.stepData) {
            this.preferences = this.stepData.preferences || '';
        }
    }

    handleChange(event) {
        this.preferences = event.target.value;
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('next', {
            detail: {
                step: 3,
                data: {
                    preferences: this.preferences
                }
            }
        }));
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }
}
