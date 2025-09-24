# XT-IDE sample program - IDE drive info
Was adopted from extremely old code, reading IDE drive information via default port 1F0h
Needs Borland C 2.0 for DOS to compile and run
**The port numbers adopted for IDE-XT port 170h, addressing scheme for revision v2**
## XT-IDE registers if you need to change the source for your port addresses
|Port|IDE-XT v1 and compatibles |IDE-XT v2|
|--|--|--|
|XX0h|(R/W) Data low byte|(R/W) Data low byte|
|XX1h|(R ) Error register (W ) Features register|(R/W) Data high byte|
|XX2h|(R/W) Sector count register|(R/W) Sector count register|
|XX3h|(R/W) LBA Low Register|--> XXAh|
|XX4h|(R/W) LBA Mid Register|(R/W) LBA Mid Register|
|XX5h|(R/W) LBA High Register|-->XXCh|
|XX6h|(R/W) Drive/Head Register|(R/W) Drive/Head Register|
|XX7h|( R) Status register ( W) Command register|--> XXEh|
|XX8h|(R/W) Data high byte|(R ) Error register (W ) Features register|
|XX9h|--|--|
|XXAh|--|(R/W) LBA Low Register|
|XXBh|--|--|
|XXCh|--|(R/W) LBA High Register|
|XXDh|--|--|
|XXEh|--|( R) Status register ( W) Command register|
|XXFh|--|--|
