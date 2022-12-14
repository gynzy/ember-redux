import Component from '@glimmer/component';
import { connect } from '@gynzy/ember-redux';

const makeUniqueSelector = () => {
  return (state) => state.low;
}

const stateToComputedFactory = () => {
  const selectItemHereOnly = makeUniqueSelector();
  return (state) => {
    const low = selectItemHereOnly(state);
    return {
      low
    }
  }
}

const dispatchToActions = dispatch => ({
  up: () => dispatch({type: 'UP'})
});

class MyClazz extends Component {
  constructor() {
    super(...arguments);
    this.color = 'yellow';
  }
}

export default connect(stateToComputedFactory, dispatchToActions)(MyClazz);
