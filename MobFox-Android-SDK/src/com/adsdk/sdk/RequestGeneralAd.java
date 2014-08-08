package com.adsdk.sdk;

import static com.adsdk.sdk.Const.RESPONSE_ENCODING;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import com.adsdk.sdk.customevents.CustomEvent;
import com.adsdk.sdk.data.ClickType;
import com.adsdk.sdk.video.VAST;
import com.adsdk.sdk.video.VASTParser;
import com.adsdk.sdk.video.VideoData;

public class RequestGeneralAd extends RequestAd<AdResponse> {

	private final static int RELOAD_AFTER_NO_AD = 20;

	public RequestGeneralAd() {
	}

	public RequestGeneralAd(InputStream xmlArg) {
		is = xmlArg;
		Log.d("Parse is null" + (is == null));
	}

	private int getInteger(final String text) {
		if (text == null)
			return 0;
		try {
			return Integer.parseInt(text);
		} catch (final NumberFormatException ex) {
			// do nothing, 0 is returned
		}
		return 0;
	}

	private String getAttribute(final Document document, final String elementName, final String attributeName) {

		NodeList nodeList = document.getElementsByTagName(elementName);
		final Element element = (Element) nodeList.item(0);
		if (element != null) {
			String attribute = element.getAttribute(attributeName);
			if (attribute.length() != 0) {
				return attribute;
			}
		}
		return null;
	}

	private String getValue(final Document document, final String name) {

		NodeList nodeList = document.getElementsByTagName(name);
		final Element element = (Element) nodeList.item(0);
		if (element != null) {
			nodeList = element.getChildNodes();
			if (nodeList.getLength() > 0)
				// if (Log.isLoggable(TAG, Log.DEBUG)) {
				// Log.d(TAG, "node value for " + name + ": " +
				// nodeList.item(0).getNodeValue());
				// }
				return nodeList.item(0).getNodeValue();
		}
		return null;
	}

	private String getTextValue(final Element element, final String name) {
		NodeList nodeList = element.getElementsByTagName(name);
		if (nodeList.getLength() > 0) {
			if (nodeList.item(0).getFirstChild() != null) {
				return nodeList.item(0).getFirstChild().getNodeValue();
			}
		}
		return "";
	}

	private List<CustomEvent> getCustomEvents(Document doc) {
		List<CustomEvent> customEvents = new ArrayList<CustomEvent>();

		NodeList elements = doc.getElementsByTagName("customevents");
		Element element = (Element) elements.item(0);
		if (element != null) {

			NodeList nodeList = element.getElementsByTagName("customevent");
			for (int i = 0; i < nodeList.getLength(); i++) {
				Node n = nodeList.item(i);
				Element el = (Element) n;
				String className = getTextValue(el, "class");
				String parameter = getTextValue(el, "parameter");
				String pixel = getTextValue(el, "pixel");
				CustomEvent event = new CustomEvent(className, parameter, pixel);
				customEvents.add(event);
			}
		}

		return customEvents;
	}

	private boolean getValueAsBoolean(final Document document, final String name) {
		return "yes".equalsIgnoreCase(this.getValue(document, name));
	}

	private int getValueAsInt(final Document document, final String name) {
		return this.getInteger(this.getValue(document, name));
	}

	private String convertStreamToString(java.io.InputStream is) {
		try {
			return new java.util.Scanner(is).useDelimiter("\\A").next();
		} catch (java.util.NoSuchElementException e) {
			return "";
		}
	}

	@Override
	AdResponse parse(final InputStream inputStream, boolean isVideo) throws RequestException {

		final DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
		DocumentBuilder db;
		final AdResponse response = new AdResponse();

		try {
			if (isVideo) {
				response.setCustomEvents(new ArrayList<CustomEvent>());
				
				VAST vast = VASTParser.createVastFromStream(inputStream);
				VideoData video = VASTParser.fillVideoDataFromVast(vast);
				if (video == null) {
					response.setType(Const.NO_AD);
					if (response.getRefresh() <= 0) {
						response.setRefresh(RELOAD_AFTER_NO_AD);
					}
				} else {
					response.setVideoData(video);
					response.setType(Const.VIDEO);
				}
			} else {
				db = dbf.newDocumentBuilder();
				InputSource src = new InputSource(inputStream);
				if (Log.LOGGING_ENABLED) {
					String sResponse = convertStreamToString(inputStream);
					Log.d("Ad RequestPerform HTTP Response: " + sResponse);
					byte[] bytes = sResponse.getBytes(RESPONSE_ENCODING);
					src = new InputSource(new ByteArrayInputStream(bytes));
				}
				src.setEncoding(Const.RESPONSE_ENCODING);
				final Document doc = db.parse(src);

				final Element element = doc.getDocumentElement();

				if (element == null)
					throw new RequestException("Document is not an xml");

				final String errorValue = this.getValue(doc, "error");
				if (errorValue != null)
					throw new RequestException("Error Response received: " + errorValue);

				final String type = element.getAttribute("type");
				element.normalize();
				if ("imageAd".equalsIgnoreCase(type)) {
					response.setType(Const.IMAGE);
					response.setBannerWidth(this.getValueAsInt(doc, "bannerwidth"));
					response.setBannerHeight(this.getValueAsInt(doc, "bannerheight"));
					final ClickType clickType = ClickType.getValue(this.getValue(doc, "clicktype"));
					response.setClickType(clickType);
					response.setClickUrl(this.getValue(doc, "clickurl"));
					response.setImageUrl(this.getValue(doc, "imageurl"));
					response.setRefresh(this.getValueAsInt(doc, "refresh"));
					response.setScale(this.getValueAsBoolean(doc, "scale"));
					response.setSkipPreflight(this.getValueAsBoolean(doc, "skippreflight"));
				} else if ("textAd".equalsIgnoreCase(type)) {
					response.setType(Const.TEXT);
					response.setText(this.getValue(doc, "htmlString"));
					String skipOverlay = this.getAttribute(doc, "htmlString", "skipoverlaybutton");
					Log.i("PARSER", "SkipOverlay: " + skipOverlay);
					if (skipOverlay != null) {
						response.setSkipOverlay(Integer.parseInt(skipOverlay));
					}
					final ClickType clickType = ClickType.getValue(this.getValue(doc, "clicktype"));
					response.setClickType(clickType);
					response.setClickUrl(this.getValue(doc, "clickurl"));
					response.setRefresh(this.getValueAsInt(doc, "refresh"));
					response.setScale(this.getValueAsBoolean(doc, "scale"));
					response.setSkipPreflight(this.getValueAsBoolean(doc, "skippreflight"));
				} else if ("mraidAd".equalsIgnoreCase(type)) {
					response.setType(Const.MRAID);
					response.setText(this.getValue(doc, "htmlString"));
					String skipOverlay = this.getAttribute(doc, "htmlString", "skipoverlaybutton");
					Log.i("PARSER", "SkipOverlay: " + skipOverlay);
					if (skipOverlay != null) {
						response.setSkipOverlay(Integer.parseInt(skipOverlay));
					}
					final ClickType clickType = ClickType.getValue(this.getValue(doc, "clicktype"));
					response.setClickType(clickType);
					response.setClickUrl(this.getValue(doc, "clickurl"));
					response.setUrlType(this.getValue(doc, "urltype"));
					response.setRefresh(0);
					response.setScale(this.getValueAsBoolean(doc, "scale"));
					response.setSkipPreflight(this.getValueAsBoolean(doc, "skippreflight"));
				} else if ("noAd".equalsIgnoreCase(type)) {
					response.setType(Const.NO_AD);
					if (response.getRefresh() <= 0) {
						response.setRefresh(RELOAD_AFTER_NO_AD);
					}
				} else {
					throw new RequestException("Unknown response type " + type);
				}

				List<CustomEvent> customEvents = this.getCustomEvents(doc);
				response.setCustomEvents(customEvents);
			}

		} catch (final ParserConfigurationException e) {
			throw new RequestException("Cannot parse Response", e);
		} catch (final SAXException e) {
			throw new RequestException("Cannot parse Response", e);
		} catch (final IOException e) {
			throw new RequestException("Cannot read Response", e);
		} catch (final Throwable t) {
			throw new RequestException("Cannot read Response", t);
		}

		return response;
	}

	@Override
	AdResponse parseTestString() throws RequestException {
		return parse(is, false);
	}
}
