import 'package:mqtt_client/mqtt_server_client.dart';

class MyMqttClient extends MqttServerClient {
  Function? onUnsubscribeCompleted;

  MyMqttClient(String brokerAddress, int port)
      : super(brokerAddress, port as String);

  @override
  void unsubscribe(String topic, {dynamic expectAcknowledge}) {
    super.unsubscribe(topic, expectAcknowledge: expectAcknowledge);

    // Handle unsubscribe response message
    onUnsubscribeCompleted?.call();
  }
}
