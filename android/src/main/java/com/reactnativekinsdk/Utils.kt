package com.reactnativekinsdk

import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.google.gson.*
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import org.kin.sdk.base.tools.Base58
import java.lang.reflect.Type


object Utils {
  @Throws(JSONException::class)
  fun convertJsonToMap(jsonObject: JSONObject): WritableMap? {
    val map: WritableMap = WritableNativeMap()
    val iterator = jsonObject.keys()
    while (iterator.hasNext()) {
      val key = iterator.next()
      when (val value = jsonObject[key]) {
          is JSONObject -> {
            map.putMap(key, convertJsonToMap(value))
          }
        is JSONArray -> {
          map.putArray(key, convertJsonToArray(value))
        }
        is Boolean -> {
          map.putBoolean(key, value)
        }
        is Int -> {
          map.putInt(key, value)
        }
        is Double -> {
          map.putDouble(key, value)
        }
        is String -> {
          map.putString(key, value)
        }
        else -> {
          map.putString(key, value.toString())
        }
      }
    }
    return map
  }

  @Throws(JSONException::class)
  private fun convertJsonToArray(jsonArray: JSONArray): WritableArray? {
    val array: WritableArray = WritableNativeArray()
    for (i in 0 until jsonArray.length()) {
      when (val value = jsonArray[i]) {
          is JSONObject -> {
            array.pushMap(convertJsonToMap(value))
          }
        is JSONArray -> {
          array.pushArray(convertJsonToArray(value))
        }
        is Boolean -> {
          array.pushBoolean(value)
        }
        is Int -> {
          array.pushInt(value)
        }
        is Double -> {
          array.pushDouble(value)
        }
        is String -> {
          array.pushString(value)
        }
        else -> {
          array.pushString(value.toString())
        }
      }
    }
    return array
  }

  class ByteArrayToBase58TypeAdapter : JsonSerializer<ByteArray?>,
    JsonDeserializer<ByteArray?> {
    @Throws(JsonParseException::class)
    override fun deserialize(
      json: JsonElement,
      typeOfT: Type?,
      context: JsonDeserializationContext?
    ): ByteArray {
      return Base58.decode(json.asString)
    }

    override fun serialize(
      src: ByteArray?,
      typeOfSrc: Type?,
      context: JsonSerializationContext?
    ): JsonElement {
      return JsonPrimitive(Base58.encode(src!!))
    }
  }
}
