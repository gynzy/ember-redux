import Route from '@ember/routing/route';
import ajax from 'dummy/utilities/ajax';
import { route } from '@gynzy/ember-redux';

var model = (dispatch) => {
  return ajax('/api/users', 'GET').then(response => dispatch({type: 'DESERIALIZE_USERS', response: response}));
};

var UsersRoute = Route.extend({
  setupController: function(controller) {
    controller.set('extended', 'yes');
  }
});

export default route({model})(UsersRoute);
