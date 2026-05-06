use adblock::lists::{FilterSet, ParseOptions};
use adblock::request::Request;
use adblock::Engine;

static DEFAULT_RULES: &[&str] = &[
    "||doubleclick.net^",
    "||googlesyndication.com^",
    "||google-analytics.com^",
    "||adservice.google.com^",
    "||adnxs.com^",
    "||popads.net^",
    "||taboola.com^",
    "||outbrain.com^",
    "||adsystem.com^",
    "||tracking.*^",
    "/ads/",
    "/adserver/",
    "/popunder",
    "/prebid",
    "##.ads",
    "##.popup",
    "##.overlay",
];

#[no_mangle]
pub extern "C" fn marlin_adblock_should_block(
    url_ptr: *const u8,
    url_len: usize,
    source_ptr: *const u8,
    source_len: usize,
    request_type_ptr: *const u8,
    request_type_len: usize,
) -> bool {
    let Some(url) = read_string(url_ptr, url_len) else {
        return false;
    };
    let source_url = read_string(source_ptr, source_len).unwrap_or_default();
    let request_type = read_string(request_type_ptr, request_type_len)
        .filter(|value| !value.is_empty())
        .unwrap_or_else(|| "other".to_string());

    let Ok(request) = Request::new(&url, &source_url, &request_type) else {
        return false;
    };

    engine().check_network_request(&request).matched
}

fn engine() -> Engine {
    let mut filter_set = FilterSet::new(false);
    filter_set.add_filters(DEFAULT_RULES, ParseOptions::default());
    Engine::from_filter_set(filter_set, true)
}

fn read_string(ptr: *const u8, len: usize) -> Option<String> {
    if ptr.is_null() || len == 0 {
        return None;
    }

    let bytes = unsafe { std::slice::from_raw_parts(ptr, len) };
    std::str::from_utf8(bytes).ok().map(ToString::to_string)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn blocks_ad_url() {
        let url = b"https://adservice.google.com/banner.js";
        let source = b"https://example.com";
        let request_type = b"script";

        assert!(marlin_adblock_should_block(
            url.as_ptr(),
            url.len(),
            source.as_ptr(),
            source.len(),
            request_type.as_ptr(),
            request_type.len(),
        ));
    }
}
