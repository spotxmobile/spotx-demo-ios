//
//  SettingsViewController.m
//  SpotX-Demo
//

#import "SettingsViewController.h"
#import "Preferences.h"

#define ToggleReuseIdentifier @"SettingsToggleCell"
#define InputReuseIdentifier @"SettingsInputCell"

// One-off class used to track the settings on this screen
@interface SettingsEntry : NSObject

@property(nonatomic, strong, nonnull) NSString* label;
@property(nonatomic, strong, nonnull) NSString* preferenceKey;
@property(nonatomic, weak, nullable)  SettingsEntry* parent;
@property(nonatomic, strong, nonnull) NSString* cellType;
@property(nonatomic, strong, nonnull) id defaultValue;
@property(nonatomic) UIKeyboardType keyboardType;

@end

@implementation SettingsEntry

+ (instancetype _Nonnull)entryWithLabel:(NSString* _Nonnull)label key:(NSString* _Nonnull)preferenceKey parent:(SettingsEntry* _Nullable)parent type:(NSString*)cellType default:(id)defaultValue keyboardType:(UIKeyboardType)keyboardType{
  SettingsEntry* entry = [[SettingsEntry alloc] init];
  entry.label = label;
  entry.preferenceKey = preferenceKey;
  entry.parent = parent;
  entry.cellType = cellType;
  entry.defaultValue = defaultValue;
  entry.keyboardType = keyboardType;
  return entry;
}

- (bool)boolValue {
  return [Preferences boolForKey:self.preferenceKey withDefault:[(NSNumber*)self.defaultValue boolValue]];
}

- (NSString*)stringValue {
  return [Preferences stringForKey:self.preferenceKey withDefault:(NSString*)self.defaultValue];
}

@end


@interface SettingsViewController ()
@property (nonatomic, weak) IBOutlet UIView *toolbarView;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray<SettingsEntry*> *fullSettingsArr;
@property (nonatomic, strong) NSArray<SettingsEntry*> *settingsArr;

@property (nonatomic, weak) UITextField *editingField;
@end


@protocol SettingsCell
@property (nonatomic, weak, readwrite) SettingsViewController *parent;
@property (nonatomic, strong, readwrite) SettingsEntry *setting;
@end


@interface SettingsToggleCell : UITableViewCell <SettingsCell>
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UISwitch *toggle;
@end


@interface SettingsInputCell : UITableViewCell <SettingsCell, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UITextField *input;
@end


@implementation SettingsViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    SettingsEntry* podEntry = [SettingsEntry entryWithLabel:@"Enable Podding" key:PREF_POD_ENABLE parent:nil type:ToggleReuseIdentifier default:@(NO) keyboardType:UIKeyboardTypeDefault];
    SettingsEntry *gdprEntry = [SettingsEntry entryWithLabel:@"Enable GDPR" key:PREF_GDPR_ENABLE parent:nil type:ToggleReuseIdentifier default:@(NO) keyboardType:UIKeyboardTypeDefault];
    self.fullSettingsArr = @[
                             podEntry,
                             [SettingsEntry entryWithLabel:@"Ad Count" key:PREF_POD_COUNT parent:podEntry type:InputReuseIdentifier default:@"3" keyboardType:UIKeyboardTypeNumberPad],
                             [SettingsEntry entryWithLabel:@"Max Ad Duration" key:PREF_POD_AD_DURATION parent:podEntry type:InputReuseIdentifier default:@"60" keyboardType:UIKeyboardTypeNumberPad],
                             [SettingsEntry entryWithLabel:@"Max Pod Duration" key:PREF_POD_DURATION parent:podEntry type:InputReuseIdentifier default:@"180" keyboardType:UIKeyboardTypeNumberPad],
                             
                             gdprEntry,
                             [SettingsEntry entryWithLabel:@"Consent String" key:PREF_GDPR_CONSENT parent:gdprEntry type:InputReuseIdentifier default:@"GDPR Consent String" keyboardType:UIKeyboardTypeASCIICapable]
                         ];
    [self updateSettings];
  }
  return self;
}

- (void)setPreferredTint:(UIColor *)color {
  [self loadViewIfNeeded];
  _toolbarView.backgroundColor = color;
}

- (void)updateSettings {
  NSMutableArray* available = [[NSMutableArray alloc] init];
  for(SettingsEntry* option in self.fullSettingsArr){
    SettingsEntry* parent = option.parent;
    // If the parent exists, and is NOT enabled, hide this item
    if(parent && ![parent boolValue]){
      continue;
    }
    [available addObject:option];
  }
  if(self.settingsArr){
    // Updating the table, so trigger an animation (if anything changed)
    if(self.settingsArr.count != available.count){
      NSMutableArray<NSIndexPath*>* deletions = [[NSMutableArray alloc] init];
      NSMutableArray<NSIndexPath*>* insertions = [[NSMutableArray alloc] init];
      // Find deletions
      [self.settingsArr enumerateObjectsUsingBlock:^(SettingsEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([available indexOfObjectIdenticalTo:obj] == NSNotFound){
          [deletions addObject:[NSIndexPath indexPathWithIndexes:(NSUInteger[]){0, idx} length:2]];
        }
      }];
      // Find insertions
      [available enumerateObjectsUsingBlock:^(SettingsEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([self.settingsArr indexOfObjectIdenticalTo:obj] == NSNotFound){
          [insertions addObject:[NSIndexPath indexPathWithIndexes:(NSUInteger[]){0, idx} length:2]];
        }
      }];
      
      self.settingsArr = available;
      [self.tableView beginUpdates];
      [self.tableView deleteRowsAtIndexPaths:deletions withRowAnimation:UITableViewRowAnimationAutomatic];
      [self.tableView insertRowsAtIndexPaths:insertions withRowAnimation:UITableViewRowAnimationAutomatic];
      [self.tableView endUpdates];
    }
  } else {
    // Filling the table for the first time
    self.settingsArr = available;
  }
}

#pragma mark - UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.settingsArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingsEntry* setting = self.settingsArr[indexPath.row];
  id<SettingsCell> cell = (id<SettingsCell>)[tableView dequeueReusableCellWithIdentifier:setting.cellType];
  [cell setParent:self];
  [cell setSetting:setting];
  return (UITableViewCell*)cell;
}

#pragma mark - Actions
- (IBAction)dismiss:(id)sender {
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)backgroundTap:(id)sender {
  [self.editingField resignFirstResponder];
  self.editingField = nil;
}

@end


@implementation SettingsToggleCell
@synthesize setting = _setting;
@synthesize parent = _parent;
-(void)setSetting:(SettingsEntry *)setting {
  _setting = setting;
  
  self.label.text = setting.label;
  BOOL settingValue = [setting boolValue];
  self.toggle.on = settingValue;
}

- (IBAction)settingToggled:(UISwitch *)sender {
  [Preferences setBool:sender.on forKey:self.setting.preferenceKey];
  // For top-level preferences, update the table if needed
  if(!self.setting.parent)
    [self.parent updateSettings];
}
@end


@implementation SettingsInputCell
@synthesize setting = _setting;
@synthesize parent = _parent;
-(void)setSetting:(SettingsEntry *)setting {
  _setting = setting;
  
  self.label.text = setting.label;
  NSString *settingValue = [setting stringValue];
  self.input.text = settingValue;
  self.input.keyboardType = setting.keyboardType;
}

#pragma mark - UITextFieldDelegate Methods
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  NSString *value = [textField.text stringByReplacingCharactersInRange:range withString:string];
  [Preferences setString:value forKey:self.setting.preferenceKey];
  return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
  [self.parent setEditingField:textField];
}
@end
