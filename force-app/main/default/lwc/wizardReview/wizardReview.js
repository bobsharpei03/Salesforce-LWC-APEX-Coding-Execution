import { LightningElement, api } from 'lwc';

export default class WizardReview extends LightningElement {
    @api step1 = {};
    @api step2 = {};
    @api step3 = {};

    // -----------------------------
    // GETTERS FOR CLEAN HTML
    // -----------------------------
    get accountName() {
        return this.step1?.accountName || '';
    }

    get industry() {
        return this.step1?.industry || '';
    }

    get firstName() {
        return this.step2?.firstName || '';
    }

    get lastName() {
        return this.step2?.lastName || '';
    }

    get email() {
        return this.step2?.email || '';
    }

    get preferences() {
        return this.step3?.preferences || '';
    }

    // -----------------------------
    // EVENTS
    // -----------------------------
    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleSubmit() {
        this.dispatchEvent(
            new CustomEvent('submitwizard', {
                detail: {
                    step1: this.step1,
                    step2: this.step2,
                    step3: this.step3
                }
            })
        );
    }
}
