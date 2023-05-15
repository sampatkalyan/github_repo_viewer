import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_response.freezed.dart';

// ^ This class is used when we query API endpoints which contain an eTag. Based on whether the eTag we receive
// ^ matches our cached eTag, the response type will either be new data or unmodified. In the second instance we
// ^ would simply return the data from our local storage and save the cost of the full API request

@freezed
class RemoteResponse<T> with _$RemoteResponse<T> {
  const RemoteResponse._();
  // will use data from local storage but will also present popup saying info may be outdated
  const factory RemoteResponse.noConnection() = _NoConnection<T>;
  // will use data from local storage
  const factory RemoteResponse.notModified({required int maxPage}) =
      _NotModified<T>;
  // will perform API call
  const factory RemoteResponse.withNewData(T data, {required int maxPage}) =
      _WithNewData<T>;
}
