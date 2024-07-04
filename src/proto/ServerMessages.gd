#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class LoginResponse:
	func _init():
		var service
		
		__gameId = PBField.new("gameId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __gameId
		data[__gameId.tag] = service
		
		__playerId = PBField.new("playerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __playerId
		data[__playerId.tag] = service
		
	var data = {}
	
	var __gameId: PBField
	func get_gameId() -> String:
		return __gameId.value
	func clear_gameId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__gameId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_gameId(value : String) -> void:
		__gameId.value = value
	
	var __playerId: PBField
	func get_playerId() -> String:
		return __playerId.value
	func clear_playerId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_playerId(value : String) -> void:
		__playerId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class NewGame:
	func _init():
		var service
		
		__gameType = PBField.new("gameType", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __gameType
		data[__gameType.tag] = service
		
		__aiId = PBField.new("aiId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __aiId
		data[__aiId.tag] = service
		
		__game = PBField.new("game", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __game
		service.func_ref = Callable(self, "new_game")
		data[__game.tag] = service
		
	var data = {}
	
	var __gameType: PBField
	func get_gameType():
		return __gameType.value
	func clear_gameType() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__gameType.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_gameType(value) -> void:
		__gameType.value = value
	
	var __aiId: PBField
	func get_aiId() -> String:
		return __aiId.value
	func clear_aiId() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__aiId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_aiId(value : String) -> void:
		__aiId.value = value
	
	var __game: PBField
	func get_game() -> GameStateP:
		return __game.value
	func clear_game() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__game.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_game() -> GameStateP:
		__game.value = GameStateP.new()
		return __game.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class NewDraft:
	func _init():
		var service
		
		__draft = PBField.new("draft", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __draft
		service.func_ref = Callable(self, "new_draft")
		data[__draft.tag] = service
		
	var data = {}
	
	var __draft: PBField
	func get_draft() -> DraftState:
		return __draft.value
	func clear_draft() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__draft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_draft() -> DraftState:
		__draft.value = DraftState.new()
		return __draft.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GetCollectionResponse:
	func _init():
		var service
		
		var __cards_default: Array[CardP] = []
		__cards = PBField.new("cards", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __cards_default)
		service = PBServiceField.new()
		service.field = __cards
		service.func_ref = Callable(self, "add_cards")
		data[__cards.tag] = service
		
	var data = {}
	
	var __cards: PBField
	func get_cards() -> Array[CardP]:
		return __cards.value
	func clear_cards() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__cards.value = []
	func add_cards() -> CardP:
		var element = CardP.new()
		__cards.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ServerMessage:
	func _init():
		var service
		
		__loginResponse = PBField.new("loginResponse", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __loginResponse
		service.func_ref = Callable(self, "new_loginResponse")
		data[__loginResponse.tag] = service
		
		__newGame = PBField.new("newGame", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __newGame
		service.func_ref = Callable(self, "new_newGame")
		data[__newGame.tag] = service
		
		__newDraft = PBField.new("newDraft", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __newDraft
		service.func_ref = Callable(self, "new_newDraft")
		data[__newDraft.tag] = service
		
		__getCollectionResponse = PBField.new("getCollectionResponse", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __getCollectionResponse
		service.func_ref = Callable(self, "new_getCollectionResponse")
		data[__getCollectionResponse.tag] = service
		
	var data = {}
	
	var __loginResponse: PBField
	func has_loginResponse() -> bool:
		return data[1].state == PB_SERVICE_STATE.FILLED
	func get_loginResponse() -> LoginResponse:
		return __loginResponse.value
	func clear_loginResponse() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__loginResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_loginResponse() -> LoginResponse:
		data[1].state = PB_SERVICE_STATE.FILLED
		__newGame.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__newDraft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__getCollectionResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__loginResponse.value = LoginResponse.new()
		return __loginResponse.value
	
	var __newGame: PBField
	func has_newGame() -> bool:
		return data[2].state == PB_SERVICE_STATE.FILLED
	func get_newGame() -> NewGame:
		return __newGame.value
	func clear_newGame() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__newGame.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_newGame() -> NewGame:
		__loginResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		data[2].state = PB_SERVICE_STATE.FILLED
		__newDraft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__getCollectionResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__newGame.value = NewGame.new()
		return __newGame.value
	
	var __newDraft: PBField
	func has_newDraft() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func get_newDraft() -> NewDraft:
		return __newDraft.value
	func clear_newDraft() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__newDraft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_newDraft() -> NewDraft:
		__loginResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__newGame.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		data[3].state = PB_SERVICE_STATE.FILLED
		__getCollectionResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__newDraft.value = NewDraft.new()
		return __newDraft.value
	
	var __getCollectionResponse: PBField
	func has_getCollectionResponse() -> bool:
		return data[4].state == PB_SERVICE_STATE.FILLED
	func get_getCollectionResponse() -> GetCollectionResponse:
		return __getCollectionResponse.value
	func clear_getCollectionResponse() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__getCollectionResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_getCollectionResponse() -> GetCollectionResponse:
		__loginResponse.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__newGame.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__newDraft.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		data[4].state = PB_SERVICE_STATE.FILLED
		__getCollectionResponse.value = GetCollectionResponse.new()
		return __getCollectionResponse.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum Phase {
	NOPHASE = 0,
	REDRAW = 1,
	BEGIN = 2,
	MAIN_BEFORE = 3,
	ATTACK = 4,
	ATTACK_PLAY = 5,
	BLOCK = 6,
	BLOCK_PLAY = 7,
	MAIN_AFTER = 8,
	END = 9
}

enum SelectFromType {
	NOTYPE = 0,
	LIST = 1,
	HAND = 3,
	PLAY = 4,
	DISCARD_PILE = 5,
	STACK = 6
}

enum GameType {
	NOGAME = 0,
	BO1_CONSTRUCTED = 1,
	P2_DRAFT = 2,
	P2_DRAFT_GAME = 3,
	AI_BO1_CONSTRUCTED = 4
}

class Table:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__creator = PBField.new("creator", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __creator
		data[__creator.tag] = service
		
		__opponent = PBField.new("opponent", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __opponent
		data[__opponent.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __creator: PBField
	func get_creator() -> String:
		return __creator.value
	func clear_creator() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__creator.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_creator(value : String) -> void:
		__creator.value = value
	
	var __opponent: PBField
	func get_opponent() -> String:
		return __opponent.value
	func clear_opponent() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__opponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_opponent(value : String) -> void:
		__opponent.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum Knowledge {
	NONE = 0,
	PURPLE = 1,
	GREEN = 2,
	RED = 3,
	BLUE = 4,
	YELLOW = 5
}

class KnowledgeGroup:
	func _init():
		var service
		
		__knowledge = PBField.new("knowledge", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __knowledge
		data[__knowledge.tag] = service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __knowledge: PBField
	func get_knowledge():
		return __knowledge.value
	func clear_knowledge() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__knowledge.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_knowledge(value) -> void:
		__knowledge.value = value
	
	var __count: PBField
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_count(value : int) -> void:
		__count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum Counter {
	NOCOUNTER = 0,
	CHARGE = 1
}

class CounterGroup:
	func _init():
		var service
		
		__counter = PBField.new("counter", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __counter
		data[__counter.tag] = service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __counter: PBField
	func get_counter():
		return __counter.value
	func clear_counter() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__counter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_counter(value) -> void:
		__counter.value = value
	
	var __count: PBField
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_count(value : int) -> void:
		__count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Blocker:
	func _init():
		var service
		
		__blockerId = PBField.new("blockerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __blockerId
		data[__blockerId.tag] = service
		
		var __possibleBlockTargets_default: Array[String] = []
		__possibleBlockTargets = PBField.new("possibleBlockTargets", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, __possibleBlockTargets_default)
		service = PBServiceField.new()
		service.field = __possibleBlockTargets
		data[__possibleBlockTargets.tag] = service
		
	var data = {}
	
	var __blockerId: PBField
	func get_blockerId() -> String:
		return __blockerId.value
	func clear_blockerId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__blockerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_blockerId(value : String) -> void:
		__blockerId.value = value
	
	var __possibleBlockTargets: PBField
	func get_possibleBlockTargets() -> Array[String]:
		return __possibleBlockTargets.value
	func clear_possibleBlockTargets() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__possibleBlockTargets.value = []
	func add_possibleBlockTargets(value : String) -> void:
		__possibleBlockTargets.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Attacker:
	func _init():
		var service
		
		__attackerId = PBField.new("attackerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __attackerId
		data[__attackerId.tag] = service
		
		var __possibleAttackTargets_default: Array[String] = []
		__possibleAttackTargets = PBField.new("possibleAttackTargets", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, __possibleAttackTargets_default)
		service = PBServiceField.new()
		service.field = __possibleAttackTargets
		data[__possibleAttackTargets.tag] = service
		
	var data = {}
	
	var __attackerId: PBField
	func get_attackerId() -> String:
		return __attackerId.value
	func clear_attackerId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__attackerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_attackerId(value : String) -> void:
		__attackerId.value = value
	
	var __possibleAttackTargets: PBField
	func get_possibleAttackTargets() -> Array[String]:
		return __possibleAttackTargets.value
	func clear_possibleAttackTargets() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__possibleAttackTargets.value = []
	func add_possibleAttackTargets(value : String) -> void:
		__possibleAttackTargets.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AttackerAssignment:
	func _init():
		var service
		
		__attackerId = PBField.new("attackerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __attackerId
		data[__attackerId.tag] = service
		
		__attacksTo = PBField.new("attacksTo", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __attacksTo
		data[__attacksTo.tag] = service
		
	var data = {}
	
	var __attackerId: PBField
	func get_attackerId() -> String:
		return __attackerId.value
	func clear_attackerId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__attackerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_attackerId(value : String) -> void:
		__attackerId.value = value
	
	var __attacksTo: PBField
	func get_attacksTo() -> String:
		return __attacksTo.value
	func clear_attacksTo() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__attacksTo.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_attacksTo(value : String) -> void:
		__attacksTo.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BlockerAssignment:
	func _init():
		var service
		
		__blockerId = PBField.new("blockerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __blockerId
		data[__blockerId.tag] = service
		
		__blockedBy = PBField.new("blockedBy", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __blockedBy
		data[__blockedBy.tag] = service
		
	var data = {}
	
	var __blockerId: PBField
	func get_blockerId() -> String:
		return __blockerId.value
	func clear_blockerId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__blockerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_blockerId(value : String) -> void:
		__blockerId.value = value
	
	var __blockedBy: PBField
	func get_blockedBy() -> String:
		return __blockedBy.value
	func clear_blockedBy() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__blockedBy.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_blockedBy(value : String) -> void:
		__blockedBy.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DamageAssignment:
	func _init():
		var service
		
		__targetId = PBField.new("targetId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __targetId
		data[__targetId.tag] = service
		
		__damage = PBField.new("damage", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __damage
		data[__damage.tag] = service
		
	var data = {}
	
	var __targetId: PBField
	func get_targetId() -> String:
		return __targetId.value
	func clear_targetId() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__targetId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_targetId(value : String) -> void:
		__targetId.value = value
	
	var __damage: PBField
	func get_damage() -> int:
		return __damage.value
	func clear_damage() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__damage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_damage(value : int) -> void:
		__damage.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class TargetSelection:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		var __targets_default: Array[String] = []
		__targets = PBField.new("targets", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, __targets_default)
		service = PBServiceField.new()
		service.field = __targets
		data[__targets.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __targets: PBField
	func get_targets() -> Array[String]:
		return __targets.value
	func clear_targets() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__targets.value = []
	func add_targets(value : String) -> void:
		__targets.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Combat:
	func _init():
		var service
		
		__health = PBField.new("health", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __health
		data[__health.tag] = service
		
		__shield = PBField.new("shield", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __shield
		data[__shield.tag] = service
		
		__attack = PBField.new("attack", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __attack
		data[__attack.tag] = service
		
		__deploying = PBField.new("deploying", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __deploying
		data[__deploying.tag] = service
		
		__blockedAttacker = PBField.new("blockedAttacker", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __blockedAttacker
		data[__blockedAttacker.tag] = service
		
		__attackTarget = PBField.new("attackTarget", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __attackTarget
		data[__attackTarget.tag] = service
		
		var __combatAbilities_default: Array[String] = []
		__combatAbilities = PBField.new("combatAbilities", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 7, true, __combatAbilities_default)
		service = PBServiceField.new()
		service.field = __combatAbilities
		data[__combatAbilities.tag] = service
		
		var __possibleBlockTargets_default: Array[String] = []
		__possibleBlockTargets = PBField.new("possibleBlockTargets", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 8, true, __possibleBlockTargets_default)
		service = PBServiceField.new()
		service.field = __possibleBlockTargets
		data[__possibleBlockTargets.tag] = service
		
	var data = {}
	
	var __health: PBField
	func get_health() -> int:
		return __health.value
	func clear_health() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__health.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_health(value : int) -> void:
		__health.value = value
	
	var __shield: PBField
	func get_shield() -> int:
		return __shield.value
	func clear_shield() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__shield.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_shield(value : int) -> void:
		__shield.value = value
	
	var __attack: PBField
	func get_attack() -> int:
		return __attack.value
	func clear_attack() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__attack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_attack(value : int) -> void:
		__attack.value = value
	
	var __deploying: PBField
	func get_deploying() -> bool:
		return __deploying.value
	func clear_deploying() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deploying.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_deploying(value : bool) -> void:
		__deploying.value = value
	
	var __blockedAttacker: PBField
	func get_blockedAttacker() -> String:
		return __blockedAttacker.value
	func clear_blockedAttacker() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__blockedAttacker.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_blockedAttacker(value : String) -> void:
		__blockedAttacker.value = value
	
	var __attackTarget: PBField
	func get_attackTarget() -> String:
		return __attackTarget.value
	func clear_attackTarget() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__attackTarget.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_attackTarget(value : String) -> void:
		__attackTarget.value = value
	
	var __combatAbilities: PBField
	func get_combatAbilities() -> Array[String]:
		return __combatAbilities.value
	func clear_combatAbilities() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__combatAbilities.value = []
	func add_combatAbilities(value : String) -> void:
		__combatAbilities.value.append(value)
	
	var __possibleBlockTargets: PBField
	func get_possibleBlockTargets() -> Array[String]:
		return __possibleBlockTargets.value
	func clear_possibleBlockTargets() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__possibleBlockTargets.value = []
	func add_possibleBlockTargets(value : String) -> void:
		__possibleBlockTargets.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Targeting:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		var __possibleTargets_default: Array[String] = []
		__possibleTargets = PBField.new("possibleTargets", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, __possibleTargets_default)
		service = PBServiceField.new()
		service.field = __possibleTargets
		data[__possibleTargets.tag] = service
		
		__minTargets = PBField.new("minTargets", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __minTargets
		data[__minTargets.tag] = service
		
		__maxTargets = PBField.new("maxTargets", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __maxTargets
		data[__maxTargets.tag] = service
		
		__targetMessage = PBField.new("targetMessage", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __targetMessage
		data[__targetMessage.tag] = service
		
		__targetingZone = PBField.new("targetingZone", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __targetingZone
		data[__targetingZone.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __possibleTargets: PBField
	func get_possibleTargets() -> Array[String]:
		return __possibleTargets.value
	func clear_possibleTargets() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__possibleTargets.value = []
	func add_possibleTargets(value : String) -> void:
		__possibleTargets.value.append(value)
	
	var __minTargets: PBField
	func get_minTargets() -> int:
		return __minTargets.value
	func clear_minTargets() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__minTargets.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_minTargets(value : int) -> void:
		__minTargets.value = value
	
	var __maxTargets: PBField
	func get_maxTargets() -> int:
		return __maxTargets.value
	func clear_maxTargets() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__maxTargets.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_maxTargets(value : int) -> void:
		__maxTargets.value = value
	
	var __targetMessage: PBField
	func get_targetMessage() -> String:
		return __targetMessage.value
	func clear_targetMessage() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__targetMessage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_targetMessage(value : String) -> void:
		__targetMessage.value = value
	
	var __targetingZone: PBField
	func get_targetingZone():
		return __targetingZone.value
	func clear_targetingZone() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__targetingZone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_targetingZone(value) -> void:
		__targetingZone.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class TargetingAbility:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		var __targets_default: Array[Targeting] = []
		__targets = PBField.new("targets", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __targets_default)
		service = PBServiceField.new()
		service.field = __targets
		service.func_ref = Callable(self, "add_targets")
		data[__targets.tag] = service
		
		__text = PBField.new("text", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __text
		data[__text.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __targets: PBField
	func get_targets() -> Array[Targeting]:
		return __targets.value
	func clear_targets() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__targets.value = []
	func add_targets() -> Targeting:
		var element = Targeting.new()
		__targets.value.append(element)
		return element
	
	var __text: PBField
	func get_text() -> String:
		return __text.value
	func clear_text() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__text.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_text(value : String) -> void:
		__text.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CardP:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		var __counters_default: Array[CounterGroup] = []
		__counters = PBField.new("counters", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 3, true, __counters_default)
		service = PBServiceField.new()
		service.field = __counters
		service.func_ref = Callable(self, "add_counters")
		data[__counters.tag] = service
		
		__depleted = PBField.new("depleted", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __depleted
		data[__depleted.tag] = service
		
		__marked = PBField.new("marked", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __marked
		data[__marked.tag] = service
		
		var __targets_default: Array[String] = []
		__targets = PBField.new("targets", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 6, true, __targets_default)
		service = PBServiceField.new()
		service.field = __targets
		data[__targets.tag] = service
		
		__canAttack = PBField.new("canAttack", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __canAttack
		data[__canAttack.tag] = service
		
		__cost = PBField.new("cost", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __cost
		data[__cost.tag] = service
		
		var __knowledgeCost_default: Array[KnowledgeGroup] = []
		__knowledgeCost = PBField.new("knowledgeCost", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 9, true, __knowledgeCost_default)
		service = PBServiceField.new()
		service.field = __knowledgeCost
		service.func_ref = Callable(self, "add_knowledgeCost")
		data[__knowledgeCost.tag] = service
		
		var __types_default: Array[String] = []
		__types = PBField.new("types", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 10, true, __types_default)
		service = PBServiceField.new()
		service.field = __types
		data[__types.tag] = service
		
		__canBlock = PBField.new("canBlock", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __canBlock
		data[__canBlock.tag] = service
		
		var __subtypes_default: Array[String] = []
		__subtypes = PBField.new("subtypes", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 12, true, __subtypes_default)
		service = PBServiceField.new()
		service.field = __subtypes
		data[__subtypes.tag] = service
		
		__delay = PBField.new("delay", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __delay
		data[__delay.tag] = service
		
		__loyalty = PBField.new("loyalty", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __loyalty
		data[__loyalty.tag] = service
		
		__canActivate = PBField.new("canActivate", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __canActivate
		data[__canActivate.tag] = service
		
		__combat = PBField.new("combat", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __combat
		service.func_ref = Callable(self, "new_combat")
		data[__combat.tag] = service
		
		__set = PBField.new("set", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __set
		data[__set.tag] = service
		
		var __attachments_default: Array[String] = []
		__attachments = PBField.new("attachments", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 18, true, __attachments_default)
		service = PBServiceField.new()
		service.field = __attachments
		data[__attachments.tag] = service
		
		__description = PBField.new("description", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __description
		data[__description.tag] = service
		
		__canPlay = PBField.new("canPlay", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __canPlay
		data[__canPlay.tag] = service
		
		__canStudy = PBField.new("canStudy", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __canStudy
		data[__canStudy.tag] = service
		
		var __playTargets_default: Array[Targeting] = []
		__playTargets = PBField.new("playTargets", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 22, true, __playTargets_default)
		service = PBServiceField.new()
		service.field = __playTargets
		service.func_ref = Callable(self, "add_playTargets")
		data[__playTargets.tag] = service
		
		var __activateTargets_default: Array[TargetingAbility] = []
		__activateTargets = PBField.new("activateTargets", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 23, true, __activateTargets_default)
		service = PBServiceField.new()
		service.field = __activateTargets
		service.func_ref = Callable(self, "add_activateTargets")
		data[__activateTargets.tag] = service
		
		__Zone = PBField.new("Zone", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __Zone
		data[__Zone.tag] = service
		
		__controller = PBField.new("controller", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __controller
		data[__controller.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __name: PBField
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __counters: PBField
	func get_counters() -> Array[CounterGroup]:
		return __counters.value
	func clear_counters() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__counters.value = []
	func add_counters() -> CounterGroup:
		var element = CounterGroup.new()
		__counters.value.append(element)
		return element
	
	var __depleted: PBField
	func get_depleted() -> bool:
		return __depleted.value
	func clear_depleted() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__depleted.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_depleted(value : bool) -> void:
		__depleted.value = value
	
	var __marked: PBField
	func get_marked() -> bool:
		return __marked.value
	func clear_marked() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__marked.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_marked(value : bool) -> void:
		__marked.value = value
	
	var __targets: PBField
	func get_targets() -> Array[String]:
		return __targets.value
	func clear_targets() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__targets.value = []
	func add_targets(value : String) -> void:
		__targets.value.append(value)
	
	var __canAttack: PBField
	func get_canAttack() -> bool:
		return __canAttack.value
	func clear_canAttack() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__canAttack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_canAttack(value : bool) -> void:
		__canAttack.value = value
	
	var __cost: PBField
	func get_cost() -> String:
		return __cost.value
	func clear_cost() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__cost.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_cost(value : String) -> void:
		__cost.value = value
	
	var __knowledgeCost: PBField
	func get_knowledgeCost() -> Array[KnowledgeGroup]:
		return __knowledgeCost.value
	func clear_knowledgeCost() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__knowledgeCost.value = []
	func add_knowledgeCost() -> KnowledgeGroup:
		var element = KnowledgeGroup.new()
		__knowledgeCost.value.append(element)
		return element
	
	var __types: PBField
	func get_types() -> Array[String]:
		return __types.value
	func clear_types() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__types.value = []
	func add_types(value : String) -> void:
		__types.value.append(value)
	
	var __canBlock: PBField
	func get_canBlock() -> bool:
		return __canBlock.value
	func clear_canBlock() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__canBlock.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_canBlock(value : bool) -> void:
		__canBlock.value = value
	
	var __subtypes: PBField
	func get_subtypes() -> Array[String]:
		return __subtypes.value
	func clear_subtypes() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__subtypes.value = []
	func add_subtypes(value : String) -> void:
		__subtypes.value.append(value)
	
	var __delay: PBField
	func get_delay() -> int:
		return __delay.value
	func clear_delay() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__delay.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_delay(value : int) -> void:
		__delay.value = value
	
	var __loyalty: PBField
	func get_loyalty() -> int:
		return __loyalty.value
	func clear_loyalty() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__loyalty.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_loyalty(value : int) -> void:
		__loyalty.value = value
	
	var __canActivate: PBField
	func get_canActivate() -> bool:
		return __canActivate.value
	func clear_canActivate() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__canActivate.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_canActivate(value : bool) -> void:
		__canActivate.value = value
	
	var __combat: PBField
	func get_combat() -> Combat:
		return __combat.value
	func clear_combat() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__combat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_combat() -> Combat:
		__combat.value = Combat.new()
		return __combat.value
	
	var __set: PBField
	func get_set() -> String:
		return __set.value
	func clear_set() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__set.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_set(value : String) -> void:
		__set.value = value
	
	var __attachments: PBField
	func get_attachments() -> Array[String]:
		return __attachments.value
	func clear_attachments() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__attachments.value = []
	func add_attachments(value : String) -> void:
		__attachments.value.append(value)
	
	var __description: PBField
	func get_description() -> String:
		return __description.value
	func clear_description() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__description.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_description(value : String) -> void:
		__description.value = value
	
	var __canPlay: PBField
	func get_canPlay() -> bool:
		return __canPlay.value
	func clear_canPlay() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__canPlay.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_canPlay(value : bool) -> void:
		__canPlay.value = value
	
	var __canStudy: PBField
	func get_canStudy() -> bool:
		return __canStudy.value
	func clear_canStudy() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__canStudy.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_canStudy(value : bool) -> void:
		__canStudy.value = value
	
	var __playTargets: PBField
	func get_playTargets() -> Array[Targeting]:
		return __playTargets.value
	func clear_playTargets() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__playTargets.value = []
	func add_playTargets() -> Targeting:
		var element = Targeting.new()
		__playTargets.value.append(element)
		return element
	
	var __activateTargets: PBField
	func get_activateTargets() -> Array[TargetingAbility]:
		return __activateTargets.value
	func clear_activateTargets() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__activateTargets.value = []
	func add_activateTargets() -> TargetingAbility:
		var element = TargetingAbility.new()
		__activateTargets.value.append(element)
		return element
	
	var __Zone: PBField
	func get_Zone() -> String:
		return __Zone.value
	func clear_Zone() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__Zone.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_Zone(value : String) -> void:
		__Zone.value = value
	
	var __controller: PBField
	func get_controller() -> String:
		return __controller.value
	func clear_controller() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		__controller.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_controller(value : String) -> void:
		__controller.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Player:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__deckSize = PBField.new("deckSize", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __deckSize
		data[__deckSize.tag] = service
		
		__energy = PBField.new("energy", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __energy
		data[__energy.tag] = service
		
		__maxEnergy = PBField.new("maxEnergy", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __maxEnergy
		data[__maxEnergy.tag] = service
		
		var __hand_default: Array[CardP] = []
		__hand = PBField.new("hand", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 6, true, __hand_default)
		service = PBServiceField.new()
		service.field = __hand
		service.func_ref = Callable(self, "add_hand")
		data[__hand.tag] = service
		
		var __play_default: Array[CardP] = []
		__play = PBField.new("play", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 7, true, __play_default)
		service = PBServiceField.new()
		service.field = __play
		service.func_ref = Callable(self, "add_play")
		data[__play.tag] = service
		
		var __discardPile_default: Array[CardP] = []
		__discardPile = PBField.new("discardPile", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 8, true, __discardPile_default)
		service = PBServiceField.new()
		service.field = __discardPile
		service.func_ref = Callable(self, "add_discardPile")
		data[__discardPile.tag] = service
		
		var __knowledgePool_default: Array[KnowledgeGroup] = []
		__knowledgePool = PBField.new("knowledgePool", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 9, true, __knowledgePool_default)
		service = PBServiceField.new()
		service.field = __knowledgePool
		service.func_ref = Callable(self, "add_knowledgePool")
		data[__knowledgePool.tag] = service
		
		__shield = PBField.new("shield", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __shield
		data[__shield.tag] = service
		
		__handSize = PBField.new("handSize", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __handSize
		data[__handSize.tag] = service
		
		__health = PBField.new("health", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __health
		data[__health.tag] = service
		
		__time = PBField.new("time", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __time
		data[__time.tag] = service
		
		var __deckColors_default: Array[KnowledgeGroup] = []
		__deckColors = PBField.new("deckColors", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 14, true, __deckColors_default)
		service = PBServiceField.new()
		service.field = __deckColors
		service.func_ref = Callable(self, "add_deckColors")
		data[__deckColors.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __username: PBField
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __deckSize: PBField
	func get_deckSize() -> int:
		return __deckSize.value
	func clear_deckSize() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__deckSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_deckSize(value : int) -> void:
		__deckSize.value = value
	
	var __energy: PBField
	func get_energy() -> int:
		return __energy.value
	func clear_energy() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__energy.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_energy(value : int) -> void:
		__energy.value = value
	
	var __maxEnergy: PBField
	func get_maxEnergy() -> int:
		return __maxEnergy.value
	func clear_maxEnergy() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__maxEnergy.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_maxEnergy(value : int) -> void:
		__maxEnergy.value = value
	
	var __hand: PBField
	func get_hand() -> Array[CardP]:
		return __hand.value
	func clear_hand() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__hand.value = []
	func add_hand() -> CardP:
		var element = CardP.new()
		__hand.value.append(element)
		return element
	
	var __play: PBField
	func get_play() -> Array[CardP]:
		return __play.value
	func clear_play() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__play.value = []
	func add_play() -> CardP:
		var element = CardP.new()
		__play.value.append(element)
		return element
	
	var __discardPile: PBField
	func get_discardPile() -> Array[CardP]:
		return __discardPile.value
	func clear_discardPile() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__discardPile.value = []
	func add_discardPile() -> CardP:
		var element = CardP.new()
		__discardPile.value.append(element)
		return element
	
	var __knowledgePool: PBField
	func get_knowledgePool() -> Array[KnowledgeGroup]:
		return __knowledgePool.value
	func clear_knowledgePool() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__knowledgePool.value = []
	func add_knowledgePool() -> KnowledgeGroup:
		var element = KnowledgeGroup.new()
		__knowledgePool.value.append(element)
		return element
	
	var __shield: PBField
	func get_shield() -> int:
		return __shield.value
	func clear_shield() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__shield.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_shield(value : int) -> void:
		__shield.value = value
	
	var __handSize: PBField
	func get_handSize() -> int:
		return __handSize.value
	func clear_handSize() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__handSize.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_handSize(value : int) -> void:
		__handSize.value = value
	
	var __health: PBField
	func get_health() -> int:
		return __health.value
	func clear_health() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__health.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_health(value : int) -> void:
		__health.value = value
	
	var __time: PBField
	func get_time() -> int:
		return __time.value
	func clear_time() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time(value : int) -> void:
		__time.value = value
	
	var __deckColors: PBField
	func get_deckColors() -> Array[KnowledgeGroup]:
		return __deckColors.value
	func clear_deckColors() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__deckColors.value = []
	func add_deckColors() -> KnowledgeGroup:
		var element = KnowledgeGroup.new()
		__deckColors.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameStateP:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__phase = PBField.new("phase", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __phase
		data[__phase.tag] = service
		
		__turnPlayer = PBField.new("turnPlayer", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __turnPlayer
		data[__turnPlayer.tag] = service
		
		__activePlayer = PBField.new("activePlayer", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __activePlayer
		data[__activePlayer.tag] = service
		
		var __attackers_default: Array[String] = []
		__attackers = PBField.new("attackers", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 5, true, __attackers_default)
		service = PBServiceField.new()
		service.field = __attackers
		data[__attackers.tag] = service
		
		var __blockers_default: Array[String] = []
		__blockers = PBField.new("blockers", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 6, true, __blockers_default)
		service = PBServiceField.new()
		service.field = __blockers
		data[__blockers.tag] = service
		
		var __stack_default: Array[CardP] = []
		__stack = PBField.new("stack", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 7, true, __stack_default)
		service = PBServiceField.new()
		service.field = __stack
		service.func_ref = Callable(self, "add_stack")
		data[__stack.tag] = service
		
		__player = PBField.new("player", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player
		service.func_ref = Callable(self, "new_player")
		data[__player.tag] = service
		
		__opponent = PBField.new("opponent", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __opponent
		service.func_ref = Callable(self, "new_opponent")
		data[__opponent.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __phase: PBField
	func get_phase():
		return __phase.value
	func clear_phase() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__phase.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_phase(value) -> void:
		__phase.value = value
	
	var __turnPlayer: PBField
	func get_turnPlayer() -> String:
		return __turnPlayer.value
	func clear_turnPlayer() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__turnPlayer.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_turnPlayer(value : String) -> void:
		__turnPlayer.value = value
	
	var __activePlayer: PBField
	func get_activePlayer() -> String:
		return __activePlayer.value
	func clear_activePlayer() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__activePlayer.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_activePlayer(value : String) -> void:
		__activePlayer.value = value
	
	var __attackers: PBField
	func get_attackers() -> Array[String]:
		return __attackers.value
	func clear_attackers() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__attackers.value = []
	func add_attackers(value : String) -> void:
		__attackers.value.append(value)
	
	var __blockers: PBField
	func get_blockers() -> Array[String]:
		return __blockers.value
	func clear_blockers() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__blockers.value = []
	func add_blockers(value : String) -> void:
		__blockers.value.append(value)
	
	var __stack: PBField
	func get_stack() -> Array[CardP]:
		return __stack.value
	func clear_stack() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__stack.value = []
	func add_stack() -> CardP:
		var element = CardP.new()
		__stack.value.append(element)
		return element
	
	var __player: PBField
	func get_player() -> Player:
		return __player.value
	func clear_player() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_player() -> Player:
		__player.value = Player.new()
		return __player.value
	
	var __opponent: PBField
	func get_opponent() -> Player:
		return __opponent.value
	func clear_opponent() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__opponent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_opponent() -> Player:
		__opponent.value = Player.new()
		return __opponent.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DraftState:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		var __decklist_default: Array[String] = []
		__decklist = PBField.new("decklist", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, __decklist_default)
		service = PBServiceField.new()
		service.field = __decklist
		data[__decklist.tag] = service
		
		__completed = PBField.new("completed", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __completed
		data[__completed.tag] = service
		
		__playerId = PBField.new("playerId", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __playerId
		data[__playerId.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> String:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_id(value : String) -> void:
		__id.value = value
	
	var __decklist: PBField
	func get_decklist() -> Array[String]:
		return __decklist.value
	func clear_decklist() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__decklist.value = []
	func add_decklist(value : String) -> void:
		__decklist.value.append(value)
	
	var __completed: PBField
	func get_completed() -> bool:
		return __completed.value
	func clear_completed() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__completed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_completed(value : bool) -> void:
		__completed.value = value
	
	var __playerId: PBField
	func get_playerId() -> String:
		return __playerId.value
	func clear_playerId() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__playerId.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_playerId(value : String) -> void:
		__playerId.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
