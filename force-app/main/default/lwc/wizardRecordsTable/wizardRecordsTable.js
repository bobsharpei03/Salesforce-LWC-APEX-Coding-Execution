import { LightningElement, wire, track } from 'lwc';
import getWizardRecords from '@salesforce/apex/WizardRecordsService.getWizardRecords';

export default class WizardRecordsTable extends LightningElement {
    @track records;
    @track error;
    @track isLoading = true;

    columns = [
        { label: 'Account', fieldName: 'accountName', type: 'text' },
        { label: 'Contact', fieldName: 'contactName', type: 'text' },
        { label: 'Email', fieldName: 'email', type: 'email' },
        { label: 'Preference', fieldName: 'Preference_Value__c', type: 'text' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    @wire(getWizardRecords)
    wiredRecords({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.records = data.map(rec => ({
                ...rec,
                accountName: rec.Contact__r?.Account?.Name,
                contactName: `${rec.Contact__r?.FirstName} ${rec.Contact__r?.LastName}`,
                email: rec.Contact__r?.Email
            }));
            this.error = null;
        } else if (error) {
            this.error = error.body?.message || 'Error loading records';
            this.records = null;
        }
    }

    refresh() {
        this.isLoading = true;
        return getWizardRecords()
            .then(data => {
                this.records = data.map(rec => ({
                    ...rec,
                    accountName: rec.Contact__r?.Account?.Name,
                    contactName: `${rec.Contact__r?.FirstName} ${rec.Contact__r?.LastName}`,
                    email: rec.Contact__r?.Email
                }));
                this.error = null;
            })
            .catch(err => {
                this.error = err.body?.message || err.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}