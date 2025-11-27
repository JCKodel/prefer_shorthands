// ignore: depend_on_referenced_packages
import 'package:shelf/shelf.dart';

Response getResponse() {
  return Response.internalServerError(); // recommends .internalServerError()
}

Future<Response> getResponseAsync() async {
  return Response.internalServerError(); // does not recommend .internalServerError()
}
