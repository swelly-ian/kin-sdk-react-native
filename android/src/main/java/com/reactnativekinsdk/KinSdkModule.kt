package com.reactnativekinsdk

import android.util.Log
import com.facebook.react.bridge.*
import com.google.gson.Gson
import org.json.JSONObject
import org.kin.sdk.base.KinAccountContext
import org.kin.sdk.base.KinAccountContextImpl
import org.kin.sdk.base.KinEnvironment
import org.kin.sdk.base.ObservationMode
import org.kin.sdk.base.models.*
import org.kin.sdk.base.network.services.AppInfoProvider
import org.kin.sdk.base.repository.InvoiceRepository
import org.kin.sdk.base.stellar.models.NetworkEnvironment
import org.kin.sdk.base.storage.KinFileStorage
import org.kin.sdk.base.tools.Base58
import org.kin.sdk.base.tools.DisposeBag
import org.kin.sdk.base.tools.Optional
import org.kin.sdk.base.tools.toByteArray
import org.kin.stellarfork.KeyPair
import java.util.*


class KinSdkModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

  val DEMO_APP_IDX = AppIdx(0)
  val DEMO_APP_SECRET_SEED = "SA7PKYPSJHOU5I6YTU6OJIOLZXREBCX6N5QK7USSXQCKS65SWSQPIMA7"
  val DEMO_APP_ACCOUNT_ID =
    KinAccount.Id("GDV4TKOCDBHB3XGCKAXWYETQRIN4RTJKSD6FQV43E2AUHORR56B4YDC4")

  var env: String = "Test"
  private val lifecycle = DisposeBag()

    override fun getName(): String {
        return "KinSdk"
    }

    // Example method
    // See https://reactnative.dev/docs/native-modules-android
    @ReactMethod
    fun multiply(a: Int, b: Int, promise: Promise) {

      promise.resolve(a * b)

    }

  @ReactMethod
  fun generateRandomKeyPair(promise: Promise) {
    val key = KeyPair.random()
    val resultData = WritableNativeMap()
    resultData.putString("secret", String(key.secretSeed))
    resultData.putString("publicKey", Base58.encode(key.asPublicKey().value))

    promise.resolve(resultData)
  }

  @ReactMethod
  fun createNewAccount(env: String, key: ReadableMap, promise: Promise) {
    try {
      val secret = key.getString("secret")!!
      this.env = env

      val kin = KinAccountContext.Builder(testKinEnvironment)
        .importExistingPrivateKey(Key.PrivateKey(secret))
        .build()

      kin.accountId.base58Encode()

      promise.resolve(true)
    } catch (e: Exception) {
      promise.reject("Error", "invalid secret")
    }

  }

  @ReactMethod
  fun resolveTokenAccounts(env: String, key: ReadableMap, promise: Promise) {
    try {
      val publicKey = key.getString("publicKey")!!
      val account = kinAccount(publicKey)
      this.env = env

      val accountContext = KinAccountContext.Builder(testKinEnvironment)
        .useExistingAccount(account)
        .build()

      accountContext.getAccount(true).then {
        val resultData = WritableNativeMap()
        resultData.putString("address", it.id.toString())
        resultData.putString("balance", it.balance.amount.toString())

        promise.resolve(resultData)
      }
    } catch (e: Exception) {
      promise.reject("Error", "invalid publicKey")
    }

  }

  @ReactMethod
  fun requestAirdrop(env: String, request: ReadableMap, promise: Promise) {
    try {
      this.env = env

      val amount: String = request.getString("amount") ?: "1"
      val publicKey: String = request.getString("publicKey") ?: ""
      val account = kinAccount(publicKey)

      val kinAccountContext = KinAccountContext.Builder(testKinEnvironment)
        .useExistingAccount(account)
        .build()

      (kinAccountContext as KinAccountContextImpl).service
        .testService
        .fundAccount(kinAccountContext.accountId)
        .then({ promise.resolve(true) }, { promise.resolve(false) })
    } catch (e: Exception) {
      promise.reject("Error", "invalid publicKey")
    }
  }

  @ReactMethod
  fun watchBalance(env: String, publicKey: String, callback: Callback) {
    this.env = env
    val account = kinAccount(publicKey)

    val context = KinAccountContext.Builder(testKinEnvironment)
      .useExistingAccount(account)
      .build()

    context.observeBalance(ObservationMode.Active)
      .add { kinBalance: KinBalance ->
        val json = JSONObject(Gson().toJson(kinBalance))
        callback.invoke(Utils.convertJsonToMap(json))
      }.disposedBy(lifecycle)

  }

  @ReactMethod
  fun sendPayment(env: String, request: ReadableMap, promise: Promise) {
    try {
      this.env = env
      val secret = request.getString("secret")!!
      val kinAccountContext = KinAccountContext.Builder(testKinEnvironment)
        .importExistingPrivateKey(Key.PrivateKey(secret))
        .build()

      val destination = request.getString("destination") ?: ""
      val amount = request.getString("amount") ?: ""
      if (destination.isEmpty()) {
        promise.reject("Error", "invalid destination")
        return
      }

      if (amount.isEmpty()) {
        promise.reject("Error", "invalid amount")
        return
      }

      var appIndex = DEMO_APP_IDX.value
      if (request.hasKey("app_index") && !request.isNull("app_index")) {
        appIndex = request.getInt("app_index")
      }

      kinAccountContext.sendKinPayment(
        KinAmount(amount),
        kinAccount(destination),
        KinBinaryMemo.Builder(appIndex)
          .setTranferType(KinBinaryMemo.TransferType.P2P)
          .build()
          .toKinMemo(),
        Optional.empty()
      ).then({ kinPayment ->
        val json = JSONObject(Gson().toJson(kinPayment))
        promise.resolve(Utils.convertJsonToMap(json))
      }, {
        promise.reject("Error", it)
      })
    } catch (e: Throwable) {
      promise.reject("Error", "invalid input data")
    }

  }

  @ReactMethod
  fun sendInvoicedPayment(env: String, request: ReadableMap, promise: Promise) {
    try {
      this.env = env

      val secret = request.getString("secret")!!
      var paymentType: KinBinaryMemo.TransferType = KinBinaryMemo.TransferType.Spend
      if (request.hasKey("paymentType") && request.isNull("paymentType")) {
        paymentType = KinBinaryMemo.TransferType.fromValue(request.getInt("paymentType"))
      }

      var appIndex = DEMO_APP_IDX.value
      if (request.hasKey("appIndex") && !request.isNull("appIndex")) {
        appIndex = request.getInt("appIndex")
      }

      val destination = request.getString("destination") ?: ""
      if (destination.isEmpty()) {
        promise.reject("Error", "invalid destination")
        return
      }

      val kinAccount: KinAccount.Id = kinAccount(destination)
      val requestItems = request.getArray("lineItems")!!

      val paymentItems = mutableListOf<Pair<String, Double>>()
      for (i in 0 until requestItems.size()) {
        requestItems.getMap(i)?.let { item ->
          val itemDescription = item.getString("description")!!
          val itemAmount = item.getDouble("amount")
          paymentItems.add(Pair(itemDescription, itemAmount))
        }
      }

      val invoice = buildInvoice(paymentItems)
      val amount = invoiceTotal(paymentItems)

      val context = KinAccountContext.Builder(testKinEnvironment)
        .importExistingPrivateKey(Key.PrivateKey(secret))
        .build()

      context.sendKinPayment(
        KinAmount(amount),
        kinAccount,
        buildMemo(invoice, paymentType, appIndex),
        Optional.of(invoice)
      )
        .then({ payment ->
          val json = JSONObject(Gson().toJson(payment))
          promise.resolve(Utils.convertJsonToMap(json))
        }) { error ->
          promise.reject("Error", error)
        }

    } catch (e: Throwable) {
      promise.reject("Error", "invalid input data")
    }
  }

  private fun buildInvoice(paymentItems: List<Pair<String, Double>>): Invoice {

    val invoiceBuilder = Invoice.Builder()

    paymentItems.forEach {
      invoiceBuilder.addLineItems(
        listOf(
          LineItem.Builder(it.first, KinAmount(it.second)).build()
        )
      )
    }

    return invoiceBuilder.build()
  }

  private fun invoiceTotal(paymentItems: List<Pair<String, Double>>): Double {
    var total = 0.0
    paymentItems.forEach {
      total += it.second
    }

    return total
  }

  private fun buildMemo(
    invoice: Invoice,
    transferType: KinBinaryMemo.TransferType,
    appIndex: Int
  ): KinMemo {
    val memo = KinBinaryMemo.Builder(appIndex).setTranferType(transferType)
    val invoiceList = InvoiceList.Builder().addInvoice(invoice).build()

    memo.setForeignKey(invoiceList.id.invoiceHash.decode())

    return memo.build().toKinMemo()
  }

  private fun kinAccount(accountId: String): KinAccount.Id {
    //resolve between Solana and Stellar format addresses
    return try {
      KinAccount.Id(Base58.decode(accountId))//Solana format
    } catch (ex: Exception) {
      KinAccount.Id(accountId) //Stellar format
    }
  }


  private val testKinEnvironment: KinEnvironment.Agora by lazy {
    KinEnvironment.Agora.Builder(if (env == "Test") NetworkEnvironment.KinStellarTestNetKin3 else NetworkEnvironment.KinStellarMainNetKin3)
      .setAppInfoProvider(object : AppInfoProvider {
        override val appInfo: AppInfo =
          AppInfo(
            DEMO_APP_IDX,
            DEMO_APP_ACCOUNT_ID,
            "Kin Demo App",
            android.R.drawable.sym_def_app_icon
          )

        override fun getPassthroughAppUserCredentials(): AppUserCreds {
          return AppUserCreds("demo_app_uid", "demo_app_user_passkey")
        }
      })
      .setMinApiVersion(4)
      .testMigration()
      .setEnableLogging()
      .setStorage(KinFileStorage.Builder("${reactContext.filesDir}/kin"))
      .build()
      .apply {
        Log.d("testKinEnvironment", "built")
        addDefaultInvoices(invoiceRepository)
      }
  }

  private fun addDefaultInvoices(invoiceRepository: InvoiceRepository) {
    val invoice1 = Invoice.Builder().apply {
      addLineItem(
        LineItem.Builder("Boombox Badger Sticker", KinAmount(25))
          .setDescription("Let's Jam!")
          .setSKU(SKU(UUID.fromString("8b154ad6-dab8-11ea-87d0-0242ac130003").toByteArray()))
          .build()
      )
      addLineItem(
        LineItem.Builder("Relaxer Badger Sticker", KinAmount(25))
          .setDescription("#HammockLife")
          .setSKU(SKU(UUID.fromString("964d1730-dab8-11ea-87d0-0242ac130003").toByteArray()))
          .build()
      )
      addLineItem(
        LineItem.Builder("Classic Badger Sticker", KinAmount(25))
          .setDescription("Nothing beats the original")
          .setSKU(SKU(UUID.fromString("cc081bd6-dab8-11ea-87d0-0242ac130003").toByteArray()))
          .build()
      )
    }.build()

    val invoice2 = Invoice.Builder().apply {
      addLineItem(
        LineItem.Builder("Fancy Tunic of Defence", KinAmount(42))
          .setDescription("+40 Defence, -9000 Style")
          .setSKU(SKU(UUID.fromString("a1b4a796-dab8-11ea-87d0-0242ac130003").toByteArray()))
          .build()
      )
      addLineItem(
        LineItem.Builder("Wizard Hat", KinAmount(99)).setDescription("+999 Mana")
          .setSKU(SKU(UUID.fromString("a911cae6-dab8-11ea-87d0-0242ac130003").toByteArray()))
          .build()
      )
    }.build()

    val invoice3 = Invoice.Builder().apply {
      addLineItem(
        LineItem.Builder("Start a Chat", KinAmount(50))
          .setSKU(SKU(UUID.fromString("cfe1f0b0-dab8-11ea-87d0-0242ac130003").toByteArray()))
          .build()
      )
    }.build()

    val invoice4 = Invoice.Builder().apply {
      addLineItem(
        LineItem.Builder("Thing", KinAmount(1))
          .setDescription("That does stuff")
          .setSKU(SKU(UUID.fromString("dac0b678-a936-44ef-abc8-365f4cae2ed1").toByteArray()))
          .build()
      )
    }.build()

    org.kin.sdk.base.tools.Promise.allAny(
      invoiceRepository.addInvoice(invoice1),
      invoiceRepository.addInvoice(invoice2),
      invoiceRepository.addInvoice(invoice3),
      invoiceRepository.addInvoice(invoice4)
    ).resolve()
  }

}
