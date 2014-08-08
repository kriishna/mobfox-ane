package com.adsdk.sdk;

import java.util.List;
import java.util.Random;

import android.net.Uri;
import android.os.Build;
import android.text.TextUtils;

public class AdRequest {
	private static final String REQUEST_TYPE_ANDROID = "android_app";
	
	private String userAgent;
	private String userAgent2;
	private String headers;
	private String deviceId;
	private String listAds;
	private String requestURL;
	private String protocolVersion;
	private String publisherId;
	private double longitude = 0.0;
	private double latitude = 0.0;
	private boolean adspaceStrict;
	private int adspaceWidth;
	private int adspaceHeight;
	private Gender gender;
	private int userAge;
	private List<String> keywords;
	
	private int videoMinDuration;
	private int videoMaxDuration;
	private boolean isVideoRequest;

	private String ipAddress;
	private String deviceId2;
	private String androidIMEI = "";
	private String androidID = "";
	private String androidAdId = "";
	private String connectionType;
	private long timestamp;

	public String getAndroidVersion() {
		return Build.VERSION.RELEASE;
	}

	public String getConnectionType() {
		return this.connectionType;
	}

	public String getDeviceId() {
		if (this.deviceId == null)
			return "";
		return this.deviceId;
	}

	public String getDeviceId2() {
		return this.deviceId2;
	}

	public String getDeviceMode() {
		return Build.MODEL;
	}

	public String getHeaders() {
		if (this.headers == null)
			return "";
		return this.headers;
	}

	public String getIpAddress() {
		if (this.ipAddress == null)
			return "";
		return this.ipAddress;
	}

	public double getLatitude() {
		return this.latitude;
	}

	public String getListAds() {
		if (this.listAds != null)
			return this.listAds;
		else
			return "";
	}

	public double getLongitude() {
		return this.longitude;
	}

	public String getProtocolVersion() {
		if (this.protocolVersion == null)
			return Const.VERSION;
		else
			return this.protocolVersion;
	}

	public String getPublisherId() {
		if (this.publisherId == null)
			return "";
		return this.publisherId;
	}

	public String getRequestType() {
		return AdRequest.REQUEST_TYPE_ANDROID;
	}

	public long getTimestamp() {
		return this.timestamp;
	}

	public String getUserAgent() {
		if (this.userAgent == null)
			return "";
		return this.userAgent;
	}

	public String getUserAgent2() {
		if (this.userAgent2 == null)
			return "";
		return this.userAgent2;
	}

	public void setConnectionType(final String connectionType) {
		this.connectionType = connectionType;
	}

	public void setDeviceId(final String deviceId) {
		this.deviceId = deviceId;
	}

	public void setDeviceId2(final String deviceId2) {
		this.deviceId2 = deviceId2;
	}

	public void setHeaders(final String headers) {
		this.headers = headers;
	}

	public void setIpAddress(final String ipAddress) {
		this.ipAddress = ipAddress;
	}

	public void setLatitude(final double latitude) {
		this.latitude = latitude;
	}

	public void setListAds(final String listAds) {
		this.listAds = listAds;
	}

	public void setLongitude(final double longitude) {
		this.longitude = longitude;
	}

	public void setProtocolVersion(final String protocolVersion) {
		this.protocolVersion = protocolVersion;
	}

	public void setPublisherId(final String publisherId) {
		this.publisherId = publisherId;
	}

	public void setTimestamp(final long timestamp) {
		this.timestamp = timestamp;
	}

	public void setUserAgent(final String userAgent) {
		this.userAgent = userAgent;
	}

	public void setUserAgent2(final String userAgent) {
		this.userAgent2 = userAgent;
	}

	@Override
	public String toString() {

		return this.toUri().toString();
	}

	public Uri toUri() {
		final Uri.Builder b = Uri.parse(this.getRequestURL()).buildUpon();
		Random r = new Random();
		int random = r.nextInt(50000);
		
		b.appendQueryParameter("rt", this.getRequestType());
		b.appendQueryParameter("v", this.getProtocolVersion());
		b.appendQueryParameter("i", this.getIpAddress());
		b.appendQueryParameter("u", this.getUserAgent());
		b.appendQueryParameter("u2", this.getUserAgent2());
		b.appendQueryParameter("s", this.getPublisherId());
		b.appendQueryParameter("o", this.getDeviceId()); 
		b.appendQueryParameter("o_androidimei", androidIMEI);
		b.appendQueryParameter("o_androidid", androidID);
		b.appendQueryParameter("o_andadvid", androidAdId);
		b.appendQueryParameter("r_random", Integer.toString(random));
		b.appendQueryParameter("o2", this.getDeviceId2());
		b.appendQueryParameter("t", Long.toString(this.getTimestamp()));
		b.appendQueryParameter("connection_type", this.getConnectionType());
		b.appendQueryParameter("listads", this.getListAds());
		b.appendQueryParameter("c_customevents", "1");
		b.appendQueryParameter("c.mraid", "1");
		if(isVideoRequest) {
			b.appendQueryParameter("r_type", "video");
			b.appendQueryParameter("r_resp", "vast20");
			if(videoMaxDuration != 0) {
				b.appendQueryParameter("v_dur_max", Integer.toString(videoMaxDuration));
			}
			if(videoMinDuration != 0) {
				b.appendQueryParameter("v_dur_min", Integer.toString(videoMinDuration));
			}
		} else {
			b.appendQueryParameter("r_type", "banner");
		}
		
		if(userAge != 0) {
			b.appendQueryParameter("demo.age", Integer.toString(userAge));
		}
		
		if (gender != null) {
			b.appendQueryParameter("demo.gender", gender.getServerParam());
		}
		
		if(keywords != null && !keywords.isEmpty()) {
			String parameter = TextUtils.join(", ", keywords);
			b.appendQueryParameter("demo.keywords", parameter);
		}
		
		b.appendQueryParameter("u_wv", this.getUserAgent());
		b.appendQueryParameter("u_br", this.getUserAgent());
		if(longitude != 0 && latitude != 0) {
			b.appendQueryParameter("longitude", Double.toString(longitude));
			b.appendQueryParameter("latitude", Double.toString(latitude));
		}
		
		if(adspaceHeight != 0 && adspaceWidth != 0) {
			if(adspaceStrict) {
				b.appendQueryParameter("adspace.strict", "1");
			} else {
				b.appendQueryParameter("adspace.strict", "0");
			}
			b.appendQueryParameter("adspace.width", Integer.toString(adspaceWidth));
			b.appendQueryParameter("adspace.height", Integer.toString(adspaceHeight));
		}

		return b.build();
	}

	public String getRequestURL() {
		return requestURL;
	}

	public void setRequestURL(String requestURL) {
		this.requestURL = requestURL;
	}

	public boolean isAdspaceStrict() {
		return adspaceStrict;
	}

	public void setAdspaceStrict(boolean adspaceStrict) {
		this.adspaceStrict = adspaceStrict;
	}

	public int getAdspaceWidth() {
		return adspaceWidth;
	}

	public void setAdspaceWidth(int adspaceWidth) {
		this.adspaceWidth = adspaceWidth;
	}

	public int getAdspaceHeight() {
		return adspaceHeight;
	}

	public void setAdspaceHeight(int adspaceHeight) {
		this.adspaceHeight = adspaceHeight;
	}

	public String getAndroidIMEI() {
		return androidIMEI;
	}

	public void setAndroidIMEI(String androidIMEI) {
		this.androidIMEI = androidIMEI;
	}

	public String getAndroidID() {
		return androidID;
	}

	public void setAndroidID(String androidID) {
		this.androidID = androidID;
	}

	public String getAndroidAdId() {
		return androidAdId;
	}

	public void setAndroidAdId(String androidAdId) {
		this.androidAdId = androidAdId;
	}

	public boolean isVideoRequest() {
		return isVideoRequest;
	}

	public void setVideoRequest(boolean isVideoRequest) {
		this.isVideoRequest = isVideoRequest;
	}

	public int getVideoMinDuration() {
		return videoMinDuration;
	}

	public void setVideoMinDuration(int videoMinDuration) {
		this.videoMinDuration = videoMinDuration;
	}

	public int getVideoMaxDuration() {
		return videoMaxDuration;
	}

	public void setVideoMaxDuration(int videoMaxDuration) {
		this.videoMaxDuration = videoMaxDuration;
	}

	public void setGender(Gender gender) {
		this.gender = gender;
	}
	
	public void setUserAge(int userAge) {
		this.userAge = userAge;
	}

	public void setKeywords(List<String> keywords) {
		this.keywords = keywords;
	}

}