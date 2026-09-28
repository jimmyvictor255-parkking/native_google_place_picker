package com.parkking.native_google_place_picker

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.widget.PlaceAutocomplete
import com.google.android.libraries.places.widget.PlaceAutocompleteActivity

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** NativeGooglePlacePickerPlugin */
class NativeGooglePlacePickerPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingResult: Result? = null

    private val placeAutocompleteRequestCode = 1001

    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "native_google_place_picker"
        )

        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(
        binding: ActivityPluginBinding
    ) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(
        binding: ActivityPluginBinding
    ) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }

            "openPlacePicker" -> {
                openPlacePicker(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun openPlacePicker(result: Result) {
        val currentActivity = activity

        if (currentActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "The Android Activity is not available.",
                null
            )
            return
        }

        if (pendingResult != null) {
            result.error(
                "ALREADY_ACTIVE",
                "The Google place picker is already open.",
                null
            )
            return
        }

        if (!Places.isInitialized()) {
            try {
                val applicationInfo =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        currentActivity.packageManager.getApplicationInfo(
                            currentActivity.packageName,
                            PackageManager.ApplicationInfoFlags.of(
                                PackageManager.GET_META_DATA.toLong()
                            )
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        currentActivity.packageManager.getApplicationInfo(
                            currentActivity.packageName,
                            PackageManager.GET_META_DATA
                        )
                    }

                val apiKey =
                    applicationInfo.metaData
                        ?.getString("com.google.android.geo.API_KEY")
                        ?.trim()

                if (apiKey.isNullOrEmpty()) {
                    result.error(
                        "MISSING_API_KEY",
                        "Google Places API key was not found in the Android manifest.",
                        null
                    )
                    return
                }

                Places.initializeWithNewPlacesApiEnabled(
                    currentActivity.applicationContext,
                    apiKey
                )
            } catch (exception: Exception) {
                result.error(
                    "PLACES_INITIALIZATION_FAILED",
                    exception.message
                        ?: "Unable to initialize Google Places SDK.",
                    null
                )
                return
            }
        }

        pendingResult = result

        try {
            val intent = PlaceAutocomplete.createIntent(currentActivity) {
                setCountries(listOf("CA"))
            }

            currentActivity.startActivityForResult(
                intent,
                placeAutocompleteRequestCode
            )
        } catch (exception: Exception) {
            pendingResult = null

            result.error(
                "PLACE_PICKER_LAUNCH_FAILED",
                exception.message
                    ?: "Unable to open Google Place Autocomplete.",
                null
            )
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean {
        if (requestCode != placeAutocompleteRequestCode) {
            return false
        }

        if (resultCode == Activity.RESULT_CANCELED) {
            pendingResult?.success(null)
            pendingResult = null
            return true
        }

        if (
            resultCode != PlaceAutocompleteActivity.RESULT_OK ||
            data == null
        ) {
            val message =
                if (data != null) {
                    PlaceAutocomplete
                        .getResultStatusFromIntent(data)
                        ?.statusMessage
                        ?: "Google Place Autocomplete returned an error."
                } else {
                    "Google Place Autocomplete returned no result."
                }

            pendingResult?.error(
                "PLACE_AUTOCOMPLETE_ERROR",
                message,
                null
            )

            pendingResult = null
            return true
        }

        val prediction =
            PlaceAutocomplete.getPredictionFromIntent(data)

        if (prediction == null) {
            pendingResult?.error(
                "NO_PREDICTION",
                "Google Place Autocomplete returned no prediction.",
                null
            )

            pendingResult = null
            return true
        }

        val sessionToken =
            PlaceAutocomplete.getSessionTokenFromIntent(data)

        val placeFields = listOf(
            Place.Field.ID,
            Place.Field.DISPLAY_NAME,
            Place.Field.FORMATTED_ADDRESS,
            Place.Field.LOCATION
        )

        val requestBuilder =
            FetchPlaceRequest.builder(
                prediction.placeId,
                placeFields
            )

        if (sessionToken != null) {
            requestBuilder.setSessionToken(sessionToken)
        }

        val currentActivity =
            activity ?: run {
                pendingResult?.error(
                    "NO_ACTIVITY",
                    "The Android Activity became unavailable.",
                    null
                )

                pendingResult = null
                return true
            }

        val placesClient =
            Places.createClient(currentActivity)

        placesClient
            .fetchPlace(requestBuilder.build())
            .addOnSuccessListener { response ->
                val place = response.place
                val location = place.location

                val placeData = hashMapOf<String, Any?>(
                    "placeId" to place.id,
                    "name" to place.displayName,
                    "address" to place.formattedAddress,
                    "lat" to location?.latitude,
                    "lng" to location?.longitude
                )

                pendingResult?.success(placeData)
                pendingResult = null
            }
            .addOnFailureListener { exception ->
                pendingResult?.error(
                    "PLACE_DETAILS_ERROR",
                    exception.message
                        ?: "Unable to retrieve place details.",
                    null
                )

                pendingResult = null
            }

        return true
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel.setMethodCallHandler(null)
    }
}