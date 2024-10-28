# How-to:

Strip requires a copy of libclang.dylib to build against.  It also requires a dynamic build of React Native:

```bash
cd packages/rn-tester
bundle install
USE_FRAMEWORKS=dynamic bundle exec pod install
# Where id= a simulator UUID
xcodebuild -workspace RNTesterPods.xcworkspace -scheme RNTester -derivedDataPath ./Foobar -destination id=90060151-D6DD-4937-9208-1F18C9FB7E59 -configuration Debug
# Produces all the frameworks in Foobar/Build/Debug-iphonsimulator/<pkg>/<name>.framework/Headers/*.h
```

We're interested in running the clang ast-dump command against these header files to extract something similar to `react-native/ReactAndroid/api/ReactAndroid.api`.

```bash
clang++ -ObjC++ -F Foobar/Build/Products/Debug-iphonesimulator/ -Xclang -ast-dump -fsyntax-only Foobar/Build/Products/Debug-iphonesimulator/React-Core/React.framework/Headers/RCTWebSocketModule.h
```

The output should be similar to:

```
public abstract class com/facebook/react/BaseReactPackage : com/facebook/react/ReactPackage {
	public fun <init> ()V
	public fun createNativeModules (Lcom/facebook/react/bridge/ReactApplicationContext;)Ljava/util/List;
	public fun createViewManagers (Lcom/facebook/react/bridge/ReactApplicationContext;)Ljava/util/List;
	public abstract fun getModule (Ljava/lang/String;Lcom/facebook/react/bridge/ReactApplicationContext;)Lcom/facebook/react/bridge/NativeModule;
	public abstract fun getReactModuleInfoProvider ()Lcom/facebook/react/module/model/ReactModuleInfoProvider;
	protected fun getViewManagers (Lcom/facebook/react/bridge/ReactApplicationContext;)Ljava/util/List;
}

public class com/facebook/react/CompositeReactPackage : com/facebook/react/ReactPackage, com/facebook/react/ViewManagerOnDemandReactPackage {
	public fun <init> (Lcom/facebook/react/ReactPackage;Lcom/facebook/react/ReactPackage;[Lcom/facebook/react/ReactPackage;)V
	public fun createNativeModules (Lcom/facebook/react/bridge/ReactApplicationContext;)Ljava/util/List;
	public fun createViewManager (Lcom/facebook/react/bridge/ReactApplicationContext;Ljava/lang/String;)Lcom/facebook/react/uimanager/ViewManager;
	public fun createViewManagers (Lcom/facebook/react/bridge/ReactApplicationContext;)Ljava/util/List;
	public fun getViewManagerNames (Lcom/facebook/react/bridge/ReactApplicationContext;)Ljava/util/Collection;
}

public final class com/facebook/react/JSEngineResolutionAlgorithm : java/lang/Enum {
	public static final field HERMES Lcom/facebook/react/JSEngineResolutionAlgorithm;
	public static final field JSC Lcom/facebook/react/JSEngineResolutionAlgorithm;
	public static fun getEntries ()Lkotlin/enums/EnumEntries;
	public static fun valueOf (Ljava/lang/String;)Lcom/facebook/react/JSEngineResolutionAlgorithm;
	public static fun values ()[Lcom/facebook/react/JSEngineResolutionAlgorithm;
}
```

You can find a detailed listing of these [here](https://docs.oracle.com/javase/specs/jvms/se17/html/jvms-4.html#jvms-4.3).

