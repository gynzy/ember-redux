import ReduxService from '@gynzy/ember-redux/services/redux';
import reducers from '../reducers/index';
import enhancers from '../enhancers/index';
import middlewares from '../middleware/index';

export default ReduxService.extend({ reducers, enhancers, middlewares });
