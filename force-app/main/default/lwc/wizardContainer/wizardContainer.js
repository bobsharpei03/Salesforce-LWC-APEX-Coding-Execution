import { LightningElement, track } from 'lwc';
import submitWizardDataApex from '@salesforce/apex/WizardController.submitWizardData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WizardContainer extends LightningElement {

    @track currentStep = 1;
    @track step1 = {};
    @track step2 = {};
    @track step3 = {};

    get isStep1() {
        return this.currentStep === 1;
    }
    get isStep2() {
        return this.currentStep === 2;
    }
    get isStep3() {
        return this.currentStep === 3;
    }
    get isReview() {
        return this.currentStep === 4;
    }


    // -----------------------------
    // STEP NAVIGATION
    // -----------------------------
    handleNext(event) {
        const { step, data } = event.detail;

        if (step === 1) {
            this.step1 = data;
            this.currentStep = 2;
        } else if (step === 2) {
            this.step2 = data;
            this.currentStep = 3;
        } else if (step === 3) {
            this.step3 = data;
            this.currentStep = 4; // Review step
        }
    }

    handleBack() {
        if (this.currentStep > 1) {
            this.currentStep -= 1;
        }
    }
    // -----------------------------
    // FINAL SUBMIT FROM REVIEW
    // -----------------------------
    handleSubmitWizard(event) {
        const payload = event.detail;

        this.submitWizardData(payload);
    }

    handleError(event) {
        this.showToast('Validation Error', event.detail, 'error');
    }

    handleSubmitWizard(event) {
    const payload = event.detail;

    this.submitWizardData(payload);
    }
    // -----------------------------
    // CALL APEX
    // -----------------------------
    submitWizardData(payload) {
        submitWizardDataApex({ wizardData: JSON.stringify(payload) })
            .then(result => {
                this.showToast(
                    'Success',
                    'Wizard records created successfully!',
                    'success'
                );

                // Refresh the table
                const table = this.template.querySelector('c-wizard-records-table');
                if (table) {
                    table.refresh();
                }

                // Reset wizard
                this.currentStep = 1;
                this.step1 = {};
                this.step2 = {};
                this.step3 = {};
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    error.body?.message || 'Something went wrong',
                    'error'
                );
            });
    }

    // -----------------------------
    // TOAST HELPER
    // -----------------------------
    /*
    async handleSubmit() {
        const payload = {
            step1: this.step1Data,
            step2: this.step2Data,
            step3: this.step3Data
        };

        try {
            const result = await submitWizardData({ wizardData: JSON.stringify(payload) });

            if (result.success) {
                this.showToast('Success', result.message, 'success');
                this.currentStep = 1; // reset wizard
            } else {
                this.showToast('Error', result.message, 'error');
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }*/

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}