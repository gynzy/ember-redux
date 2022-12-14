import Route from '@ember/routing/route';
import ajax from 'dummy/utilities/ajax';
import { route } from '@gynzy/ember-redux';

var model = (dispatch) => {
  return ajax('/api/users', 'GET').then(response => dispatch({type: 'DESERIALIZE_USERS', response: response}));
};

const ThunkRoute = Route.extend({
  actions: {
    // This loading action is invoked by Ember when the model returns a
    // promise. This is used in tests to ensure that this model hooks
    // into Ember's loading substates.
    loading() {
      window.loadingInvoked = true;
    }
  }
});

export default route({model})(ThunkRoute);
