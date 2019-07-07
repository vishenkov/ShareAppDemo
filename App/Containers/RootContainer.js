import React, { Component } from 'react'
import { View, StatusBar } from 'react-native'
import { NativeModules } from 'react-native';
import ReduxNavigation from '../Navigation/ReduxNavigation'
import { connect } from 'react-redux'
import StartupActions from '../Redux/StartupRedux'
import ReduxPersist from '../Config/ReduxPersist'

// Styles
import styles from './Styles/RootContainerStyles'

const ShareExtension = NativeModules.ShareViewController;

class RootContainer extends Component {
  async componentDidMount () {
    // if redux persist is not active fire startup action
    if (!ReduxPersist.active) {
      this.props.startup()
    }

    console.tron.log({ NativeModules });

    try {
      const data = await ShareExtension.data();
      console.tron.log({ data });
    } catch (error) {
      console.tron.log({ error });
    }
  }

  render () {
    return (
      <View style={styles.applicationView}>
        <StatusBar barStyle='light-content' />
        <ReduxNavigation />
      </View>
    )
  }
}

// wraps dispatch to create nicer functions to call within our component
const mapDispatchToProps = (dispatch) => ({
  startup: () => dispatch(StartupActions.startup())
})

export default connect(null, mapDispatchToProps)(RootContainer)
