import Component from '@ember/component';
import { connect } from '@gynzy/ember-redux';
import { bumpTwice } from '../../actions/index';

var stateToComputed = function(state) {
  return {
    low: state.low
  };
};

var dispatchToActions = {
  bumpTwice
};

class MyClazzz extends Component {
  constructor() {
    super(...arguments);
    this.color = 'green';
  }
}

export default connect(stateToComputed, dispatchToActions)(MyClazzz);
