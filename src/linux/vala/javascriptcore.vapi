/* javascriptcore.vapi
 *
 * Copyright (C) 2010 Sam Thursfield <ssssam@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

/* NOTE: this binding is quite inaccurate and you will have to a bunch of fixing for some functions.
 *
 * This is a basic interface to JSCore, a more friendly binding is Seed. See
 * http://live.gnome.org/Seed for more information.
 */

[CCode (lower_case_cprefix = "js_", cheader_filename = "JavaScriptCore/JavaScript.h")]
namespace JSCore {
	[Compact]
	[CCode (cname = "void", free_function = "JSContextGroupRelease")]
	public class ContextGroup {
		[CCode (cname = "JSContextGroupCreate")]
		public ContextGroup();

		[CCode (cname = "JSContextCreateInGroup")]
		public ContextGroup Retain ();
	}


	[Compact]
	[CCode (cname = "void")]
	public class Context {
		/* Script Evaluation */
		[CCode (cname = "JSEvaluateScript")]
		public Value evaluate_script (String script,
		                                      Object? thisObject,
		                                      String? sourceURL,
		                                      int startingLineNumber,
		                                      out Value exception);

		[CCode (cname = "JSCheckScriptSyntax")]
		public bool check_script_syntax (JSCore.String script,
		                                 JSCore.String? sourceURL, int startingLineNumber,
		                                 out JSCore.Value exception);

		[CCode (cname = "JSGarbageCollect")]
		public void garbage_collect ();

		[CCode (cname = "JSContextGetGlobalObject")]
		public JSCore.Object get_global_object ();

		[CCode (cname = "JSContextGetGroup")]
		public ContextGroup get_group ();
	}


	/* Same as Context */
	[Compact]
	[CCode (cname = "void", free_function = "JSGlobalContextRelease")]
	public class GlobalContext: Context {
		[CCode (cname = "JSGlobalContextCreate")]
		public GlobalContext (Class globalObjectClass);

		[CCode (cname = "JSGlobalContextCreateInGroup")]
		public GlobalContext.in_group (ContextGroup group, Class globalObjectClass);

		[CCode (cname = "JSGlobalContextRetain")]
		public GlobalContext retain ();
	}


	/* FIXME: not sure the significance of this. Vala strings are UTF-8 while it seems
	 *   JSCore uses UCS-2 or UTF-16 ...
	     #if !defined(WIN32) && !defined(_WIN32) && !defined(__WINSCW__) \
	       && !(defined(__CC_ARM) || defined(__ARMCC__))
	       typedef unsigned short JSChar;
	     #else
	       typedef wchar_t JSChar;
	     #endif
	 */

	[Compact]
	[CCode (cname = "void", free_function = "JSStringRelease")]
	public class String {
		[CCode (cname = "JSStringCreateWithCharacters")]
		public String.with_characters (ushort *chars, size_t num_chars);
		
		[CCode (cname = "JSStringCreateWithUTF8CString")]
		public String.with_utf8_c_string (string _string);

		[CCode (cname = "JSStringRetain")]
		public String retain ();

		[CCode (cname = "JSStringGetLength")]
		public size_t get_length ();

		[CCode (cname = "JSStringGetCharactersPtr")]
		public ushort *get_characters_ptr ();

		[CCode (cname = "JSStringGetMaximumUTF8CStringSize")]
		public size_t get_maximum_utf8_c_string_size ();

		[CCode (cname = "JSStringGetUTF8CString")]
		public size_t get_utf8_c_string (char *buffer, size_t buffer_size);

		[CCode (cname = "JSStringIsEqual")]
		public bool is_equal (String b);

		[CCode (cname = "JSStringIsEqualToUTF8CString")]
		public bool is_equal_to_utf8_c_string (string b);
	}


	[CCode (has_target = false)]
	public delegate void                  ObjectInitializeCallback        (Context ctx,
	                                                                      JSCore.Object object);

	[CCode (has_target = false)]
	public delegate void                  ObjectFinalizeCallback          (JSCore.Object object);

	[CCode (has_target = false)]
	public delegate bool                  ObjectHasPropertyCallback       (Context ctx,
	                                                                       JSCore.Object object,
	                                                                       JSCore.String propertyName);

	[CCode (has_target = false)]
	public delegate JSCore.Value  ObjectGetPropertyCallback       (Context ctx,
	                                                                       JSCore.Object object,
	                                                                       JSCore.String propertyName,
	                                                                       out JSCore.Value exception);

	[CCode (has_target = false)]
	public delegate bool                  ObjectSetPropertyCallback       (Context ctx,
	                                                                       JSCore.Object object,
	                                                                       JSCore.String propertyName,
	                                                                       JSCore.Value _value,
	                                                                       out JSCore.Value exception);

	[CCode (has_target = false)]
	public delegate bool                  ObjectDeletePropertyCallback    (Context ctx,
	                                                                       JSCore.Object object,
	                                                                       JSCore.String propertyName,
	                                                                       out JSCore.Value exception);

	[CCode (has_target = false)]
	public delegate void                  ObjectGetPropertyNamesCallback  (Context ctx,
	                                                                       JSCore.Object object,
	                                                                       PropertyNameAccumulator propertyNames);

	[CCode (cname = "JSObjectCallAsFunctionCallback", has_target = false)]
	public delegate JSCore.Value  ObjectCallAsFunctionCallback    (Context ctx,
	                                                                       JSCore.Object function,
	                                                                       JSCore.Object thisObject,
                                                                           [CCode (array_length_pos=3.9, array_length_type="size_t")]
	                                                                       JSCore.Value[] arguments,
	                                                                       out JSCore.Value exception);

	[CCode (has_target = false)]
	public delegate JSCore.Object ObjectCallAsConstructorCallback (Context ctx,
	                                                                       JSCore.Object constructor,
                                                                           [CCode (array_length_pos=2.9, array_length_type="size_t")]
	                                                                       JSCore.Value[] arguments,
	                                                                       out JSCore.Value exception);

	[CCode (has_target = false)]
	public delegate bool                  ObjectHasInstanceCallback       (Context ctx,
	                                                                       JSCore.Object constructor,
	                                                                       JSCore.Value possibleInstance,
	                                                                       out JSCore.Value exception);

	[CCode (has_target = false)]
	public delegate JSCore.Value  ObjectConvertToTypeCallback     (Context ctx,
	                                                                       JSCore.Object object,
	                                                                       JSCore.Type type,
	                                                                       out JSCore.Value exception);

	public struct StaticValue {
		public string name;
		public ObjectGetPropertyCallback getProperty;
		public ObjectSetPropertyCallback setProperty;
		public PropertyAttribute attributes;
	}

	[CCode (cname = "JSStaticFunction")]
	public struct StaticFunction {
		public string name;
		public ObjectCallAsFunctionCallback callAsFunction;
		public PropertyAttribute attributes;
	}

	[CCode (cname = "JSClassDefinition")]
	public struct ClassDefinition {
		public int version;
		public ClassAttribute attributes;

		public string className;
		public JSCore.Class parentClass;

		public StaticValue *staticValues;
		public StaticFunction *staticFunction;

		public ObjectInitializeCallback          initialize;
		public ObjectFinalizeCallback            finalize;
		public ObjectHasPropertyCallback         hasProperty;
		public ObjectGetPropertyCallback         getProperty;
		public ObjectSetPropertyCallback         setProperty;
		public ObjectDeletePropertyCallback      deleteProperty;
		public ObjectGetPropertyNamesCallback    getPropertyNames;
		public ObjectCallAsFunctionCallback      callAsFunction;
		public ObjectCallAsConstructorCallback   callAsConstructor;
		public ObjectHasInstanceCallback         hasInstance;
		public ObjectConvertToTypeCallback       convertToType;
	}

	[CCode (cname="kJSClassDefinitionEmpty")]
	extern ClassDefinition ClassDefinitionEmpty;

	//typedef unsigned JSClassAttributes;
	[CCode (cprefix="kJSClassAttribute")]
	[Flags]
	public enum ClassAttribute {
		None, NoAutomaticPrototype
	}

	[Compact]
	[CCode (cname = "void", free_function = "JSClassRelease")]
	public class Class {
		[CCode (cname="JSClassCreate")]
		public Class (ClassDefinition definition);

		[CCode (cname="JSClassRetain")]
		public Class retain (Class js_class);
	}


	//typedef unsigned JSPropertyAttributes;
	[CCode (cprefix="kJSPropertyAttribute")]
	[Flags]
	public enum PropertyAttribute {
		None, ReadOnly, DontEnum, DontDelete
	}

	[Compact]
	[CCode (cname = "void *", free_function = "JSPropertyNameArrayRelease")]
	public class PropertyNameArray {
		[CCode (cname = "JSPropertyNameArrayRetain")]
		public PropertyNameArray retain ();

		[CCode (cname = "JSPropertyNameArrayGetCount")]
		public size_t get_count ();

		[CCode (cname = "JSPropertyNameArrayGetNameAtIndex")]
		public JSCore.String get_name_at_index (size_t index);
	}

	[Compact]
	[CCode (cname = "void")]
	public class PropertyNameAccumulator {
		[CCode (cname = "JSPropertyNameAccumulatorAddName")]
		public void add_name (String property_name);
	}


	[CCode (cprefix="kJSType")]
	public enum Type {
		Undefined, Null, Boolean, Number, String, Object
	}

	[Compact]
	/* FIXME: free_function causes a warning */
	[CCode (cname = "void", free_function = "")]
	public class Value {
		[CCode (cname = "JSValueMakeUndefined")]
		public Value.undefined (Context ctx);

		[CCode (cname = "JSValueMakeNull")]
		public Value.null (Context ctx);

		[CCode (cname = "JSValueMakeBoolean")]
		public Value.boolean (Context ctx, bool boolean);

		[CCode (cname = "JSValueMakeNumber")]
		public Value.number (Context ctx, double number);

		[CCode (cname = "JSValueMakeString")]
		public Value.string (Context ctx, String js_string);

		[CCode (cname = "JSValueGetType", instance_pos=1.1)]
		public JSCore.Type get_type (Context ctx);

		[CCode (cname = "JSValueIsUndefined", instance_pos=1.1)]
		public bool is_undefined (Context ctx);

		[CCode (cname = "JSValueIsNull", instance_pos=1.1)]
	public bool is_null (Context ctx);

		[CCode (cname = "JSValueIsBoolean", instance_pos=1.1)]
		public bool is_boolean (Context ctx);

		[CCode (cname = "JSValueIsNumber", instance_pos=1.1)]
		public bool is_number (Context ctx);

		[CCode (cname = "JSValueIsString", instance_pos=1.1)]
		public bool is_string (Context ctx);

		[CCode (cname = "JSValueIsObject", instance_pos=1.1)]
		public bool is_object (Context ctx);

		[CCode (cname = "JSValueIsNull", instance_pos=1.1)]
		public bool is_object_of_class (Context ctx, Value js_value, Class js_class);

		[CCode (cname = "JSValueIsEqual", instance_pos=1.1)]
		public bool is_equal (Context ctx, Value b, Value *exception);

		[CCode (cname = "JSValueIsStrictEqual", instance_pos=1.1)]
		public bool is_strict_equal (Context ctx, Value b);

		[CCode (cname = "JSValueIsInstanceOfConstructor", instance_pos=1.1)]
		public bool is_instance_of_constructor (Context ctx, Value js_value, Object constructor,
		                                        Value *exception);

		[CCode (cname = "JSValueToBoolean", instance_pos=1.1)]
		public bool to_boolean (Context ctx);

		[CCode (cname = "JSValueToNumber", instance_pos=1.1)]
		public int to_number (Context ctx, Value *exception);

		[CCode (cname = "JSValueToStringCopy", instance_pos=1.1)]
		public JSCore.String to_string_copy (Context ctx, Value *exception);

		[CCode (cname = "JSValueToObject", instance_pos=1.1)]
		public Object to_object (Context ctx, Value *exception);

		[CCode (cname = "JSValueProtect", instance_pos=1.1)]
		public void protect (Context ctx);

		[CCode (cname = "JSValueUnprotect", instance_pos=1.1)]
		public void unprotect (Context ctx);
	}


	[Compact]
	/* FIXME: causes a warning */
	[CCode (cname = "void", free_function = "")]
	public class Object: JSCore.Value {
		[CCode (cname = "JSObjectMake")]
		public Object (Context ctx, Class js_class, void *data);

		[CCode (cname = "JSObjectMakeFunctionWithCallback")]
		public Object.function_with_callback (Context ctx, JSCore.String name,
		                                      ObjectCallAsFunctionCallback callAsFunction);

		[CCode (cname = "JSObjectMakeConstructor")]
		public Object.constructor (Context ctx, JSCore.Class js_class,
		                           ObjectCallAsConstructorCallback callAsConstructor);

		[CCode (cname = "JSObjectMakeArray")]
		public Object.array (Context ctx, [CCode (array_length_pos=1.9, array_length_type="size_t")]JSCore.Value[] arguments,
		                     out JSCore.Value exception);

		[CCode (cname = "JSObjectMakeDate")]
		public Object.date (Context ctx, size_t argument_count,
		                    JSCore.Value[] arguments,
		                    out JSCore.Value exception);

		[CCode (cname = "JSObjectMakeError")]
		public Object.error (Context ctx, size_t argument_count,
		                     JSCore.Value[] arguments,
		                     out JSCore.Value exception);

		[CCode (cname = "JSObjectMakeRegExp")]
		public Object.regexp (Context ctx, size_t argument_count,
		                     JSCore.Value[] arguments,
		                     out JSCore.Value exception);

		[CCode (cname = "JSObjectMakeFunction")]
		public Object.function (Context ctx, JSCore.String name,
		                        uint parameter_count, JSCore.String[] parameter_names,
		                        JSCore.String body, JSCore.String source_url,
		                        int starting_line_number, out JSCore.Value exception);

		[CCode (cname = "JSObjectGetPrototype", instance_pos=1.1)]
		public JSCore.Value get_prototype (Context ctx);

		[CCode (cname = "JSObjectSetPrototype", instance_pos=1.1)]
		public JSCore.Value set_prototype (Context ctx, JSCore.Value _value);

		[CCode (cname = "JSObjectHasProperty", instance_pos=1.1)]
		public bool has_property (Context ctx, JSCore.String propertyName);

		[CCode (cname = "JSObjectGetProperty", instance_pos=1.1)]
		public JSCore.Value get_property (Context ctx, JSCore.String propertyName,
		                                          out JSCore.Value exception);

		[CCode (cname = "JSObjectSetProperty", instance_pos=1.1)]
		public void set_property (Context ctx, JSCore.String property_name, 
		                          JSCore.Value _value, PropertyAttribute attributes, 
		                          out JSCore.Value exception);

		[CCode (cname = "JSObjectDeleteProperty", instance_pos=1.1)]
		public bool delete_property (Context ctx, JSCore.String property_name, 
		                             out JSCore.Value exception);

		[CCode (cname = "JSObjectGetPropertyAtIndex", instance_pos=1.1)]
		public JSCore.Value get_property_at_index (Context ctx, uint property_index,
		                                                   out JSCore.Value exception);

		[CCode (cname = "JSObjectSetPropertyAtIndex", instance_pos=1.1)]
		public void set_property_at_index (Context ctx, uint property_index,
		                                   JSCore.Value _value,
		                                   out JSCore.Value exception);

		[CCode (cname = "JSObjectGetPrivate")]
		public void *get_private ();

		[CCode (cname = "JSObjectSetPrivate")]
		public bool set_private (void *data);

		[CCode (cname = "JSObjectIsFunction", instance_pos=1.1)]
		public bool is_function (Context ctx);

		[CCode (cname = "JSObjectCallAsFunction", instance_pos=1.1)]
		public unowned JSCore.Value call_as_function (Context ctx,
		                                              JSCore.Object? this_object,
                                                      [CCode (array_length_pos=2.9, array_length_type="size_t")]
		                                              JSCore.Value[]? arguments,
		                                              out JSCore.Value exception);

		[CCode (cname = "JSObjectIsConstructor", instance_pos=1.1)]
		public bool is_constructor (Context ctx);

		[CCode (cname = "JSObjectCallAsConstructor", instance_pos=1.1)]
		public unowned JSCore.Object call_as_constructor (Context ctx,
                                                          [CCode (array_length_pos=1.9, array_length_type="size_t")]
		                                                  JSCore.Value[]? arguments,
		                                                  out JSCore.Value exception);

		[CCode (cname = "JSObjectCopyPropertyNames", instance_pos=1.1)]
		public unowned PropertyNameArray copy_property_names (Context ctx);

		/* Handy for debugging */
		public void dump (JSCore.Context ctx, GLib.FileStream stream) {
			JSCore.String js_string = this.to_string_copy (ctx, null);
			char *c_string = new char[1024];
			js_string.get_utf8_c_string (c_string, 1023);

			unowned PropertyNameArray property_names = this.copy_property_names (ctx);

			stream.printf ("Object: %s, %i properties\n", (string)c_string, (int)property_names.get_count());
			delete c_string;

			for (var i=0; i<property_names.get_count(); i++) {
				js_string = property_names.get_name_at_index (i);
				c_string = new char[1024];
				js_string.get_utf8_c_string (c_string, 1023);
				stream.printf ("\t%i: %s\n", i, (string)c_string);
				delete c_string;
			}
		}
	}
}
