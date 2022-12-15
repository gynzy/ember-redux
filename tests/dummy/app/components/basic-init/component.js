import Component from '@ember/component';
import { get } from '@ember/object';
import { connect } from '@gynzy/ember-redux';

var stateToComputed = state => ({
  low: state.low
});

var ConnectComponent = Component.extend({

  init() {
    this._super(...arguments);
    this.hello = get(this, 'low');
  }

});

export default connect(stateToComputed)(ConnectComponent);
