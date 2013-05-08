package com.mopub.mobileads;


import ru.redspell.lightning.LightActivity;
import com.mopub.mobileads.MoPubView;
import com.mopub.mobileads.MoPubInterstitial;
import android.widget.AbsoluteLayout.LayoutParams;

public class LightningWrapper {


	public static void createBanner(final String unitId, final int mlCallback) {
		android.util.Log.d("LIGHTNING", "CREATE BANNER");
		LightActivity.instance.runOnUiThread(
				new Runnable () {
					@Override
					public void run() {
						final MoPubView mAdView = new MoPubView(LightActivity.instance);
						mAdView.setAdUnitId(unitId);
						LightActivity.instance.lightView.queueEvent(
							new Runnable () {
								@Override
								public void run() {
									bannerCreated(mAdView,mlCallback);
								}
							});
					}
				});
	}

	private static native void bannerCreated(MoPubView banner, int mlcallback);

	private static class BannerListener implements com.mopub.mobileads.MoPubView.BannerAdListener {

		private int mlcallback;

		public BannerListener(int c) {
			this.mlcallback = c;
		}

		public void onBannerLoaded(final MoPubView banner) {
			android.util.Log.d("LIGHTNING", "BANNER SUCCESSFULLY LOADED " + banner.getWidth() + ":" + banner.getHeight());
			LightActivity.instance.lightView.queueEvent(
					new Runnable () {
						@Override
						public void run() {
							ocamlOK(mlcallback);
						}
					});
    }



		public void onBannerFailed(final MoPubView banner, MoPubErrorCode errorCode) {
			android.util.Log.d("LIGHTNING", "BANNER FAILED TO LOAD");
			final String msg = errorCode.toString();
			LightActivity.instance.lightView.queueEvent(
					new Runnable () {
						@Override
						public void run() {
							ocamlError(mlcallback,msg);
						}
					});
		}
		
		public void onBannerClicked(MoPubView banner) {}
		public void onBannerExpanded(MoPubView banner) {}
		public void onBannerCollapsed(MoPubView banner) {}

	  private static native void ocamlOK(int mlcallback);
	  private static native void ocamlError(int mlcallback,String message);
	}

	static void loadBanner(final MoPubView banner,final int mlCallback) {
		LightActivity.instance.runOnUiThread(new Runnable () {
			@Override
			public void run () {
				banner.setBannerAdListener(new BannerListener(mlCallback));
				banner.loadAd();
			}
		});
	}

	static void showBanner(final MoPubView banner,int x, int y) {
		final LayoutParams lp = new LayoutParams(-1,-1,x,y); 
		LightActivity.instance.runOnUiThread(
				new Runnable () {
					@Override
					public void run() {
						LightActivity.instance.viewGrp.addView(banner,lp);
						android.util.Log.d("LIGHTNING", "BANNER ADDED TO VIEW " + banner.getWidth() + ":" + banner.getHeight());
					}
				});
	}

	static void hideBannder(final MoPubView banner) {
		LightActivity.instance.runOnUiThread(
				new Runnable () {
					@Override
					public void run() {
						LightActivity.instance.viewGrp.removeView(banner);
					}
				});
	}


	static void destroyBanner(final MoPubView banner) {
		LightActivity.instance.runOnUiThread(
				new Runnable () {
					@Override
					public void run() {
						banner.destroy();
					}
				});
	}



	public static void createInterstitial(final String unitId, final int mlCallback) {
		android.util.Log.d("LIGHTNING", "CREATE INTERSTITIAL");
		LightActivity.instance.runOnUiThread(
				new Runnable () {
					@Override
					public void run() {
						final MoPubInterstitial inters = new MoPubInterstitial(LightActivity.instance,unitId);
						LightActivity.instance.lightView.queueEvent(
							new Runnable () {
								@Override
								public void run() {
									interstitialCreated(inters,mlCallback);
								}
							});
					}
				});
	}

	private static native void interstitialCreated(MoPubInterstitial inters, int mlcallback);

	private static class InterstitialListener implements com.mopub.mobileads.MoPubInterstitial.InterstitialAdListener {

		private int loadCallback;
		public int dismissCallback;

		public InterstitialListener (int c) {
			loadCallback = c;
		}

		public void onInterstitialLoaded(final MoPubInterstitial inters) {
			android.util.Log.d("LIGHTNING", "INTERSTITIAL SUCCESSFULLY LOADED"); 
			Runnable r;
					if (inters.isReady ())
						r = new Runnable () {
							@Override
							public void run() {
								ocamlOK(loadCallback);
							}
						};
					else 
						r = new Runnable () {
							@Override
							public void run() {
								ocamlError(loadCallback,"Not ready");
							}
						};
			LightActivity.instance.lightView.queueEvent(r);
    }

		public void onInterstitialFailed(final MoPubInterstitial banner, MoPubErrorCode errorCode) {
			android.util.Log.d("LIGHTNING", "INTERSTITIAL FAILED TO LOAD");
			final String msg = errorCode.toString();
			LightActivity.instance.lightView.queueEvent(
					new Runnable () {
						@Override
						public void run() {
							ocamlError(loadCallback,msg);
						}
					});
		}
		
		public void onInterstitialShown(MoPubInterstitial inters) {}
		public void onInterstitialDismissed(MoPubInterstitial inters) {
			android.util.Log.d("LIGHTNING", "INTERSTITIAL DISMISSED");
			LightActivity.instance.lightView.queueEvent(
					new Runnable () {
						@Override
						public void run() {
							ocamlCallback(dismissCallback);
						}
					});
		}

	  private static native void ocamlOK(int mlcallback);
	  private static native void ocamlError(int mlcallback,String message);
	  private static native void ocamlCallback(int mlcallback);
	}

	static void loadInterstitial(final MoPubInterstitial inters,final int mlCallback) {
		LightActivity.instance.runOnUiThread(new Runnable () {
			@Override
			public void run () {
				inters.setInterstitialAdListener(new InterstitialListener(mlCallback));
				inters.load();
			}
		});
	}

	static void showInterstitial(final MoPubInterstitial inters, int dismissCallback) {
		InterstitialListener l = (InterstitialListener)inters.getInterstitialAdListener();
		l.dismissCallback = dismissCallback;
		LightActivity.instance.runOnUiThread(
				new Runnable () {
					@Override
					public void run() {
						inters.show();
					}
				});
	}

	static void destroyInterstitial(final MoPubInterstitial inters) {
		LightActivity.instance.runOnUiThread(
				new Runnable () {
					@Override
					public void run() {
						inters.destroy();
					}
				});
	}

}
