#ifndef UIKIT2_KB_VECTOR_H
#define UIKIT2_KB_VECTOR_H

namespace KB {
	// sizeof = 0xC.
	template<typename T>
	class Vector<T> {
	private:
		unsigned m_size;		// 0
		unsigned m_capacity;	// 4
		T* m_elements;			// 8
		
		template <typename T> static void quick_sort_partition(T*, unsigned, unsigned, unsigned, int(*compare)(const T&, const T&));
		template <typename T> static void quick_sort(T*, unsigned, unsigned, int(*compare)(const T&, const T&));
		
		template <typename T> static T null_value();
		
	public:
		template <typename T> Vector(const Vector<T>&);
		template <typename T> Vector<T>& operator= (const Vector<T>&);
		
		void ensure_capacity(unsigned);
				
		void fill(unsigned, unsigned);
		void trim(unsigned);
		void clear();
		
		template<typename T> void insert_at(unsigned index, const T& obj);
		void remove_at(unsigned index);
	};	
};


#endif