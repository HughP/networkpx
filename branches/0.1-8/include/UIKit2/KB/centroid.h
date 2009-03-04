#ifndef UIKIT2_KB_CENTROID_H
#define UIKIT2_KB_CENTROID_H

#include <UIKit2/KB/String.h>
#include <UIKit2/KB/Hashmap.h>
#include <UIKit2/KB/FPoint.h>

namespace KB {
	// static Hashmap<KB::String, KB::FPoint> str_centroid_map;
	// static char char_centroid_lut;
	
	FPoint kb_key_centroid(const String&);
	void kb_clear_key_centroids();
	void kb_register_key_centroid(const String&, const FPoint&);
};

#endif