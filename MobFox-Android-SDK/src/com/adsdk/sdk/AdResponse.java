package com.adsdk.sdk;

import java.util.List;

import com.adsdk.sdk.customevents.CustomEvent;
import com.adsdk.sdk.data.ClickType;
import com.adsdk.sdk.video.VideoData;

public class AdResponse implements Ad {

	public static final String WEB = "web";
	public static final String OTHER = "other";

	private static final long serialVersionUID = 3271938798582141269L;
	private int type;
	private int bannerWidth;
	private int bannerHeight;
	private String text;
	private int skipOverlay = 0;
	private String imageUrl;
	private ClickType clickType;
	private String clickUrl;
	private String urlType;
	private int refresh;
	private List<CustomEvent> customEvents;
	private boolean scale;
	private boolean skipPreflight;
	private long timestamp;
	private boolean horizontalOrientationRequested;
	private VideoData videoData;

	public int getBannerHeight() {
		return this.bannerHeight;
	}

	public int getBannerWidth() {
		return this.bannerWidth;
	}

	public ClickType getClickType() {
		return this.clickType;
	}

	public String getClickUrl() {
		return this.clickUrl;
	}

	public String getImageUrl() {
		return this.imageUrl;
	}

	public int getRefresh() {
		return this.refresh;
	}

	public String getText() {
		return this.text;
	}

	@Override
	public int getType() {
		return this.type;
	}

	public String getUrlType() {
		return this.urlType;
	}

	public boolean isScale() {
		return this.scale;
	}

	public boolean isSkipPreflight() {
		return this.skipPreflight;
	}

	public void setBannerHeight(final int bannerHeight) {
		this.bannerHeight = bannerHeight;
	}

	public void setBannerWidth(final int bannerWidth) {
		this.bannerWidth = bannerWidth;
	}

	public void setClickType(final ClickType clickType) {
		this.clickType = clickType;
	}

	public void setClickUrl(final String clickUrl) {
		this.clickUrl = clickUrl;
	}

	public void setImageUrl(final String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public void setRefresh(final int refresh) {
		this.refresh = refresh;
	}

	public void setScale(final boolean scale) {
		this.scale = scale;
	}

	public void setSkipPreflight(final boolean skipPreflight) {
		this.skipPreflight = skipPreflight;
	}

	public void setText(final String text) {
		this.text = text;
	}

	@Override
	public void setType(final int adType) {
		this.type = adType;
	}

	public void setUrlType(final String urlType) {
		this.urlType = urlType;
	}

	@Override
	public String toString() {
		return "Response [refresh=" + this.refresh + ", type=" + this.type
				+ ", bannerWidth=" + this.bannerWidth + ", bannerHeight="
				+ this.bannerHeight + ", text=" + this.text + ", imageUrl="
				+ this.imageUrl + ", clickType=" + this.clickType
				+ ", clickUrl=" + this.clickUrl + ", urlType=" + this.urlType
				+ ", scale=" + this.scale + ", skipPreflight="
				+ this.skipPreflight + "]";
	}

	public int getSkipOverlay() {
		return skipOverlay;
	}

	public void setSkipOverlay(int skipOverlay) {
		this.skipOverlay = skipOverlay;
	}

	public List<CustomEvent> getCustomEvents() {
		return customEvents;
	}

	public void setCustomEvents(List<CustomEvent> customEvents) {
		this.customEvents = customEvents;
	}

	public long getTimestamp() {
		return timestamp;
	}

	public void setTimestamp(long timestamp) {
		this.timestamp = timestamp;
	}

	public VideoData getVideoData() {
		return videoData;
	}

	public void setVideoData(VideoData videoData) {
		this.videoData = videoData;
	}

	public boolean isHorizontalOrientationRequested() {
		return horizontalOrientationRequested;
	}

	public void setHorizontalOrientationRequested(boolean horizontalOrientationRequested) {
		this.horizontalOrientationRequested = horizontalOrientationRequested;
	}


}
