import {expect, test} from "@playwright/test";

test.describe('language switcher', () => {
    test.beforeEach(async ({page}) => {
        await page.goto('http://localhost:8080');
    });

    test('has at least german and english options', async ({page}) => {
        const headerElement = page.locator('header');
        const langSwitcher = headerElement.getByRole('combobox');
        const options = await langSwitcher.locator('option').all();
        const optionValues =
            await Promise.all( options.map(async option => await option.getAttribute('value')));
        expect(optionValues.length).toBeGreaterThanOrEqual(2);
        expect(optionValues).toContain('de');
        expect(optionValues).toContain('en');
    });

    test('works on switcher', async ({page}) => {
        const headerElement = page.locator('header');
        const langSwitcher = headerElement.getByRole('combobox');
        await expect(langSwitcher).toHaveValue('en')
        await expect(headerElement).toHaveText(/English/);
        await langSwitcher.selectOption({value: 'de'});
        await expect(langSwitcher).toHaveValue("de")
        await expect(headerElement).toHaveText(/Deutsch/);
    });
});