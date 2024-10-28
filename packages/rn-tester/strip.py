import clang.cindex
import inspect

def l(depth, msg):
  print("\t"*depth + msg)

def method(node, depth):
  l(depth, f'🔬 [METHOD][{node.spelling}] ({node.kind})');
  for child in node.get_children():
    dump(child, depth+1);

def parse_protocol(node, depth):
  """
  Show protocol descriptions
  """
  l(depth, f'🔬 [PROTOCOL][{node.spelling}] ({node.kind})');
  for child in node.get_children():
    l(depth+1, f'<{child.kind}> ')
    # dump(child, depth+1)

def parse_interface(node, depth):
  """
  Show protocol descriptions
  """
  l(depth, f'🔬 [PROTOCOL][{node.spelling}] ({node.kind})');
  l(depth, f'@interface {node.displayname} -> {len(list(node.get_arguments()))}')
  dump(node.type, depth+1)
  # ! get_arguments, get_tokens
  #for child in node.get_tokens():
  #  l(depth+1, f'<{child.kind}> → {child.spelling}')
    # dump(child, depth+1)

def dump(node, depth):
  """Dump debugging information about a node"""
  l(depth, f'🔬 [{node.spelling}] ({node.kind})');
  for access in filter(lambda s: not s.startswith('_'), dir(node)):
    try:
      v = getattr(node, access, None)
      l(depth, f'\t{access} -> {v()}') 
    except:
      try:
        l(depth, f'\t{access} -> {v}')
      except:
        l(depth, f'\t{access} -> ????')

def walk(node, depth):
  """Recursively walk the AST"""

  l(depth, f'> [{node.spelling}] ({node.kind})');
  if node.kind == clang.cindex.CursorKind.OBJC_PROTOCOL_DECL:
    parse_protocol(node, depth+1)
  elif node.kind == clang.cindex.CursorKind.OBJC_INTERFACE_DECL:
    parse_interface(node, depth+1)

  for child in node.get_children():
    walk(child, depth+1);


if __name__ == '__main__':
  clang.cindex.Config.set_library_file('/Users/blakef/homebrew/opt/llvm//lib/libclang.dylib')

  index = clang.cindex.Index.create()
  header = '/Users/blakef/src/react-native/packages/rn-tester/Foobar/Build/Products/Debug-iphonesimulator/React-Core/React.framework/Headers/RCTWebSocketModule.h'
  tu = index.parse(header, ['-x', 'objective-c++'])  # Ensure correct path and language option

  print('-'*80)
  print('File: ' + header)
  print("> " + "> ".join(open(header, 'r').readlines()));
  print('-'*80)
  print('-'*80)
  print('Parsing the header file...')
  print('-'*80)
  node = tu.cursor;

  print(node.kind)
  walk(node, 0);
