import { route } from '@gynzy/ember-redux';

var beforeModel = (dispatch) => {
  let roles = JSON.parse(document.querySelector('[preload-roles]')?.dataset.configuration ?? '{}');
  dispatch({type: 'ADD_ROLES', roles: roles});
};

export default route({beforeModel})();
