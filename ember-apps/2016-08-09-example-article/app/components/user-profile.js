import Ember from 'ember';
const { Component, inject } = Ember;

// https://github.com/mitchlloyd/ember-islands#usage

export default Component.extend({
  store: inject.service(),

  init() {
    this._super(...arguments);
    this.description = this.get('innerContent').htmlSafe();
  },

  actions: {
    showDetails() {
      this.get('store').findRecord('user', this.get('id')).then((user) => {
        this.set('user', user);
      });

      this.set('isShowingDetails', true);
    }
  }
});
